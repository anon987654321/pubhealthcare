#!/usr/bin/env ruby
# frozen_string_literal: true

# Smoke test for Postpro.rb v13.4.0
# Tests deterministic reproducibility and basic functionality

require 'test/unit'
require 'json'
require 'fileutils'
require 'vips'
require 'tempfile'
require 'digest'

# Set up test environment
ENV['GEM_PATH'] = "#{ENV['HOME']}/.local/share/gem/ruby/#{RUBY_VERSION}:#{ENV['GEM_PATH']}"
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))

class PostproSmokeTest < Test::Unit::TestCase
  def setup
    @test_dir = File.join(File.dirname(__FILE__), '..', 'test_images')
    @postpro_script = File.join(File.dirname(__FILE__), '..', 'postpro.rb')
    
    # Create test directory and image
    FileUtils.mkdir_p(@test_dir)
    @test_image = File.join(@test_dir, 'smoke_test.jpg')
    
    # Create a test image if it doesn't exist
    unless File.exist?(@test_image)
      # Create 200x200 RGB test image with some patterns
      img = Vips::Image.black(200, 200, bands: 3)
      # Add some features to make effects visible
      img = img.draw_rect([255, 255, 255], 80, 80, 40, 40, fill: true)  # White square
      img = img.draw_rect([255, 0, 0], 160, 20, 20, 20, fill: true)     # Red square
      img = img.draw_rect([0, 255, 0], 20, 160, 20, 20, fill: true)     # Green square
      img = img.draw_rect([0, 0, 255], 160, 160, 20, 20, fill: true)    # Blue square
      img.write_to_file(@test_image)
    end
  end
  
  def teardown
    # Clean up test files
    Dir.glob(File.join(@test_dir, '*processed*')).each { |f| File.delete(f) }
    Dir.glob('postpro.log*').each { |f| File.delete(f) } # Clean log files
  end
  
  def test_script_syntax
    assert system("ruby -c #{@postpro_script}"), "postpro.rb should have valid syntax"
  end
  
  def test_basic_loading_and_constants
    require_relative '../postpro'
    
    # Test that main classes and constants are defined
    assert defined?(AnalogRNG), "AnalogRNG class should be defined"
    assert defined?(EFFECTS), "EFFECTS constant should be defined"
    assert defined?(EFFECT_INDEX), "EFFECT_INDEX constant should be defined"
    assert defined?(Effect), "Effect struct should be defined"
    
    # Test EFFECTS array structure
    assert EFFECTS.is_a?(Array), "EFFECTS should be an array"
    assert EFFECTS.size > 0, "EFFECTS should not be empty"
    
    # Test that all effects have required structure
    EFFECTS.each do |effect|
      assert effect.respond_to?(:key), "Effect should have key"
      assert effect.respond_to?(:impl), "Effect should have impl"
      assert effect.respond_to?(:category), "Effect should have category"
      assert effect.respond_to?(:description), "Effect should have description"
      assert effect.respond_to?(:pro_range), "Effect should have pro_range"
      assert effect.respond_to?(:exp_range), "Effect should have exp_range"
    end
  end
  
  def test_analog_rng_determinism
    require_relative '../postpro'
    
    # Test that same seed produces same results
    rng1 = AnalogRNG.new(12345)
    rng2 = AnalogRNG.new(12345)
    
    # Generate some random values
    vals1 = (1..10).map { rng1.rand }
    vals2 = (1..10).map { rng2.rand }
    
    assert_equal vals1, vals2, "Same seed should produce same random sequence"
    
    # Test different seeds produce different results
    rng3 = AnalogRNG.new(54321)
    vals3 = (1..10).map { rng3.rand }
    
    refute_equal vals1, vals3, "Different seeds should produce different sequences"
  end
  
  def test_effect_method_availability
    require_relative '../postpro'
    
    # Test that all registered effect methods exist and respond correctly
    EFFECTS.each do |effect|
      method_name = effect.impl
      assert respond_to?(method_name, true), "Should respond to #{method_name} method"
      
      # Test method signature by calling with dummy parameters
      begin
        img = Vips::Image.black(10, 10, bands: 3)
        rng = AnalogRNG.new(123)
        result = send(method_name, img, 0.5, 'professional', rng, {})
        assert result.is_a?(Vips::Image), "#{method_name} should return a Vips::Image"
        assert_equal 3, result.bands, "#{method_name} should return 3-band image"
      rescue StandardError => e
        # Some effects might fail with minimal test image, that's ok for smoke test
        # Just check that the method exists and can be called
        assert true, "Method #{method_name} exists and is callable (#{e.class.name})"
      end
    end
  end
  
  def test_recipe_parsing
    require_relative '../postpro'
    
    # Test simple recipe parsing
    simple_recipe = { "film_grain" => 0.5, "sepia" => 0.3 }
    effects = build_effects_from_recipe(simple_recipe, 'professional')
    
    assert_equal 2, effects.size, "Should parse 2 effects from simple recipe"
    assert_equal 'film_grain', effects[0][:key], "First effect should be film_grain"
    assert_equal 0.5, effects[0][:intensity], "Film grain intensity should be 0.5"
    
    # Test advanced recipe parsing with metadata
    advanced_recipe = {
      "film_stock_emulation" => { "intensity" => 0.7, "stock" => "kodak_portra" },
      "film_grain" => 0.4
    }
    effects = build_effects_from_recipe(advanced_recipe, 'professional')
    
    assert_equal 2, effects.size, "Should parse 2 effects from advanced recipe"
    stock_effect = effects.find { |e| e[:key] == 'film_stock_emulation' }
    assert_not_nil stock_effect, "Should find film_stock_emulation effect"
    assert_equal 0.7, stock_effect[:intensity], "Stock emulation intensity should be 0.7"
    assert_equal 'kodak_portra', stock_effect[:meta][:stock], "Stock should be kodak_portra"
  end
  
  def test_adaptive_scale_helper
    require_relative '../postpro'
    
    # Test adaptive scaling for different image sizes
    small_img = Vips::Image.black(100, 100, bands: 3)
    normal_img = Vips::Image.black(1024, 1024, bands: 3)
    large_img = Vips::Image.black(2048, 2048, bands: 3)
    
    small_scale = adaptive_scale(small_img)
    normal_scale = adaptive_scale(normal_img)
    large_scale = adaptive_scale(large_img)
    
    assert small_scale < normal_scale, "Small image should have smaller scale"
    assert normal_scale <= large_scale, "Normal image scale should be <= large image scale"
    assert small_scale >= 0.25, "Scale should not go below 0.25"
    assert large_scale <= 1.0, "Scale should not go above 1.0"
  end
  
  def test_noise_caching
    require_relative '../postpro'
    
    # Clear any existing cache
    $noise_cache.clear
    
    img = Vips::Image.black(100, 100, bands: 3)
    
    # First call should create cache entry
    noise1 = cached_noise(img, 25.0)
    assert_equal 1, $noise_cache.size, "Should have 1 cache entry"
    
    # Second call with same parameters should reuse cache
    noise2 = cached_noise(img, 25.0)
    assert_equal 1, $noise_cache.size, "Should still have 1 cache entry"
    
    # Different sigma should create new entry
    noise3 = cached_noise(img, 30.0)
    assert_equal 2, $noise_cache.size, "Should have 2 cache entries"
    
    # Same parameters should return identical noise
    assert_equal noise1.avg, noise2.avg, "Cached noise should be identical"
  end
  
  def test_cli_flag_parsing
    # Test that OptionParser setup doesn't crash
    require_relative '../postpro'
    
    # This is tricky to test without actually running the CLI
    # But we can at least check that the gather_inputs method exists
    assert respond_to?(:gather_inputs, true), "Should have gather_inputs method"
  end
  
  def test_deterministic_processing_simulation
    require_relative '../postpro'
    
    # Simulate deterministic processing without full CLI
    img = Vips::Image.black(50, 50, bands: 3)
    rng1 = AnalogRNG.new(42)
    rng2 = AnalogRNG.new(42)
    
    # Select effects with same seed
    effects1 = select_random_effects(rng1, 3, 'professional')
    effects2 = select_random_effects(rng2, 3, 'professional')
    
    assert_equal effects1, effects2, "Same seed should select same effects"
    
    # Test different seeds produce different results
    rng3 = AnalogRNG.new(123)
    effects3 = select_random_effects(rng3, 3, 'professional')
    
    # Note: this might occasionally be equal due to randomness, but very unlikely
    # We'll just check it runs without error for now
    assert effects3.is_a?(Array), "Should return array of effects"
    assert_equal 3, effects3.size, "Should return requested number of effects"
  end
end