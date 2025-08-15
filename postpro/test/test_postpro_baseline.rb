#!/usr/bin/env ruby
# frozen_string_literal: true

# Baseline test for current postpro.rb functionality
# This validates the current implementation before upgrade

require 'test/unit'
require 'json'
require 'fileutils'
require 'vips'

# Set up test environment
ENV['GEM_PATH'] = "#{ENV['HOME']}/.local/share/gem/ruby/#{RUBY_VERSION}:#{ENV['GEM_PATH']}"
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))

class PostproBaselineTest < Test::Unit::TestCase
  def setup
    @test_dir = File.join(File.dirname(__FILE__), '..', 'test_images')
    @postpro_script = File.join(File.dirname(__FILE__), '..', 'postpro.rb')
    
    # Create test directory and image
    FileUtils.mkdir_p(@test_dir)
    @test_image = File.join(@test_dir, 'baseline_test.jpg')
    
    # Create a simple test image if it doesn't exist
    unless File.exist?(@test_image)
      # Create 100x100 RGB test image
      img = Vips::Image.black(100, 100, bands: 3)
      # Add some pattern to make effects visible
      img = img.draw_rect([255, 255, 255], 40, 40, 20, 20, fill: true)
      img.write_to_file(@test_image)
    end
  end
  
  def teardown
    # Clean up test files
    Dir.glob(File.join(@test_dir, '*processed*')).each { |f| File.delete(f) }
  end
  
  def test_script_syntax
    assert system("ruby -c #{@postpro_script}"), "postpro.rb should have valid syntax"
  end
  
  def test_basic_loading
    require_relative '../postpro'
    
    # Test that basic constants are defined
    assert defined?(EFFECTS), "EFFECTS constant should be defined"
    assert defined?(PROMPT), "PROMPT constant should be defined"
    
    # Test that EFFECTS hash contains expected keys
    expected_effects = [:film_grain, :light_leaks, :lens_distortion, :sepia]
    expected_effects.each do |effect|
      assert EFFECTS.key?(effect), "EFFECTS should contain #{effect}"
    end
  end
  
  def test_load_image_exists
    require_relative '../postpro'
    
    # Test image loading functionality indirectly
    assert File.exist?(@test_image), "Test image should exist"
    
    # Test that we can load an image with Vips
    img = Vips::Image.new_from_file(@test_image)
    assert_equal 100, img.width
    assert_equal 100, img.height
    assert_equal 3, img.bands
  end
  
  def test_effects_respond_to_methods
    require_relative '../postpro'
    
    # Test that effect methods are defined
    EFFECTS.each do |name, method_sym|
      assert respond_to?(method_sym, true), "Should respond to #{method_sym} method"
    end
  end
  
  def test_json_parsing_functionality
    # Test basic JSON functionality that the script will need
    test_recipe = { "film_grain" => 0.5, "sepia" => 0.3 }
    json_str = JSON.generate(test_recipe)
    parsed = JSON.parse(json_str)
    
    assert_equal test_recipe, parsed
  end
end