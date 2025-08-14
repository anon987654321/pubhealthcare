#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Postpro.rb – Analog & Cinematic Post-Processing Engine
# Version: 13.4.0
# Updated: 2025-08-14
#
# Key Features:
# - Professional vs Experimental modes (subtle vs bold look shaping)
# - Deterministic seed option (--seed or SEED env var)
# - Centralized RNG (AnalogRNG)
# - Effect registry with metadata & bounded per-mode intensity ranges
# - JSON recipe support (simple numeric or hash with metadata)
# - Optional polishing pipeline (film stock emulation + grain + scratches)
# - Shared highlight mask reuse (bloom & halation) for performance
# - Adaptive blur scaling for small images
# - Noise cache reuse between grain & VHS degrade where permissible
# - Per-effect Δavg logging and overall stack delta
# - Graceful image normalization (grayscale → sRGB, drop extra bands)
# - Error resilience; pipeline continues on individual effect failure
#
# Requirements:
#   libvips >= 8.14.x
#   gem install --user-install ruby-vips tty-prompt
#
# License / Disclaimer:
#   Trademarks of camera manufacturers belong to their owners. This tool provides
#   independent analog-style transformations and does not replicate proprietary recipes.

require 'vips'
require 'logger'
require 'tty-prompt'
require 'json'
require 'time'
require 'optparse'

# ----------------------------
# Logging
# ----------------------------
File.write('postpro.log', '') if File.exist?('postpro.log')
$logger     = Logger.new('postpro.log', 'daily')
$cli_logger = Logger.new($stdout)
$logger.level     = Logger::DEBUG
$cli_logger.level = Logger::INFO

PROMPT = TTY::Prompt.new

# ----------------------------
# RNG Wrapper for Determinism
# ----------------------------
class AnalogRNG
  def initialize(seed = nil)
    @seed = seed
    @rng = seed ? Random.new(seed.to_i) : Random.new
  end
  attr_reader :seed
  def rand(*args)
    @rng.rand(*args)
  end
  def sample(enum, n = nil)
    if n
      enum.sample(n, random: @rng)
    else
      enum.sample(random: @rng)
    end
  end
end

# ----------------------------
# Effect Registry & Helpers
# ----------------------------
Effect = Struct.new(:key, :impl, :category, :description, :pro_range, :exp_range)

def choose_intensity(rng, mode, pro_range, exp_range)
  range = (mode == 'professional') ? pro_range : exp_range
  val = rng.rand(range)
  [[val, 0.0].max, 5.0].min
end

# Base effect list
EFFECTS = [
  Effect.new('film_grain', :film_grain, 'texture', 'Adds stochastic film-like grain', 0.2..0.8, 0.5..2.0),
  Effect.new('light_leaks', :light_leaks, 'light', 'Simulates lens/body light intrusions', 0.2..0.6, 0.5..1.5),
  Effect.new('lens_distortion', :lens_distortion, 'optical', 'Curves frame edges', 0.1..0.3, 0.3..0.9),
  Effect.new('sepia', :sepia, 'color', 'Warm vintage tone mapping', 0.2..0.6, 0.5..1.2),
  Effect.new('bleach_bypass', :bleach_bypass, 'contrast', 'High contrast desaturation', 0.3..0.7, 0.6..1.4),
  Effect.new('lomo', :lomo, 'color', 'Saturated vignette aesthetic', 0.3..0.7, 0.6..1.5),
  Effect.new('golden_hour_glow', :golden_hour_glow, 'light', 'Warm center glow', 0.2..0.6, 0.5..1.2),
  Effect.new('cross_process', :cross_process, 'color', 'Color shifts inspired by chemical x-proc', 0.2..0.7, 0.6..1.5),
  Effect.new('bloom_effect', :bloom_effect, 'light', 'Highlight diffusion / bloom', 0.3..0.8, 0.7..1.8),
  Effect.new('film_halation', :film_halation, 'light', 'Red-orange halation around highlights', 0.2..0.6, 0.5..1.2),
  Effect.new('teal_and_orange', :teal_and_orange, 'color', 'Cinematic color contrast', 0.3..0.7, 0.6..1.4),
  Effect.new('day_for_night', :day_for_night, 'color', 'Simulated night grading', 0.2..0.6, 0.5..1.2),
  Effect.new('anamorphic_simulation', :anamorphic_simulation, 'optical', 'Horizontal stretch mimic', 0.2..0.5, 0.4..1.0),
  Effect.new('chromatic_aberration', :chromatic_aberration, 'optical', 'Color fringing at edges', 0.2..0.5, 0.6..1.5),
  Effect.new('vhs_degrade', :vhs_degrade, 'degrade', 'Analog tape noise & scanlines', 0.2..0.6, 0.7..1.6),
  Effect.new('color_fade', :color_fade, 'color', 'Aged low-sat fade', 0.2..0.6, 0.5..1.2),
  Effect.new('film_scratches', :film_scratches, 'texture', 'Vertical emulsion scratches', 0.2..0.6, 0.5..1.2),
  Effect.new('film_stock_emulation', :film_stock_emulation, 'color', 'Kodak / Fuji-esque tonal bias', 0.2..0.6, 0.4..1.0)
].freeze

EFFECT_INDEX = EFFECTS.to_h { |e| [e.key, e] }
EXPERIMENTAL_BIAS_KEYS = %w[vhs_degrade chromatic_aberration lens_distortion bloom_effect film_halation lomo anamorphic_simulation]

# ----------------------------
# Image Loading & Normalization
# ----------------------------
def load_image(path)
  raise "Missing file: #{path}" unless File.exist?(path)
  img = Vips::Image.new_from_file(path)
  if img.bands < 3
    img = img.colourspace('srgb')
  elsif img.bands > 3
    img = img.extract_band(0, n: 3)
  end
  img
end

# ----------------------------
# Intensity Utilities
# ----------------------------
def normalize_intensity(raw)
  val = (Float(raw) rescue 0.5)
  [[val, 0.0].max, 5.0].min
end

# ----------------------------
# Adaptive Helpers
# ----------------------------
def adaptive_scale(image)
  # Scale radius related operations for small images (<1024) to prevent oversoften
  min_dim = [image.width, image.height].min
  scale = min_dim / 1024.0
  scale = 0.25 if scale < 0.25 # hard floor so very small images still show effect
  scale = 1.0 if scale > 1.0
  scale
end

# Shared caches (per run) for performance. Simple Hash; not thread-safe (single-process use).
$noise_cache = {}

def cached_noise(image, sigma)
  key = [image.width, image.height, sigma.round(2)]
  if (n = $noise_cache[key])
    n
  else
    n = Vips::Image.gaussnoise(image.width, image.height, sigma: sigma)
    $noise_cache[key] = n
  end
end

# ----------------------------
# Effect Implementations
# Each must accept: (image, intensity, mode, rng, meta = {}) and return Vips::Image
# ----------------------------

def film_grain(image, intensity, _mode, rng, meta = {})
  sigma = 25 * intensity
  noise = cached_noise(image, sigma)
  noise = noise.bandjoin([noise] * (image.bands - 1)) if noise.bands < image.bands
  (image + noise * 0.18).cast('uchar')
end

def light_leaks(image, intensity, mode, rng, _meta = {})
  count = (mode == 'professional') ? 1 : rng.rand(2..4)
  overlay = Vips::Image.black(image.width, image.height, bands: image.bands)
  count.times do
    x = rng.rand(image.width)
    y = rng.rand(image.height)
    radius = (image.width / rng.rand(3..5)) * intensity
    color = if mode == 'professional'
              [220, 140, 60]
            else
              [255, rng.rand(150..220), rng.rand(50..140)]
            end
    overlay = overlay.draw_circle(color, x, y, radius, fill: true)
  end
  overlay = overlay.gaussblur(20 * intensity)
  (image + overlay * 0.25).cast('uchar')
end

def lens_distortion(image, intensity, _mode, _rng, _meta = {})
  identity = Vips::Image.identity(image.width, image.height)
  factor = 0.15 * intensity
  dx = identity.linear([1 + factor], [0]).cast('float')
  dy = identity.linear([1 + factor], [0]).cast('float')
  image.mapim(dx.bandjoin(dy))
rescue StandardError
  image
end

def sepia(image, intensity, _mode, _rng, _meta = {})
  m = [
    0.393, 0.769, 0.189,
    0.349, 0.686, 0.168,
    0.272, 0.534, 0.131
  ]
  image.recomb(m).linear([intensity], [0]).cast('uchar')
end

def bleach_bypass(image, intensity, _mode, _rng, _meta = {})
  gray = image.colourspace('b-w')
  blend = image * 0.6 + gray * 0.4
  out = image.linear([1 + 0.2 * intensity], [12 * intensity]) + blend * 0.5 * intensity
  out.clip(0, 255).cast('uchar')
end

def lomo(image, intensity, _mode, _rng, _meta = {})
  sat = image.linear([1 + 0.2 * intensity], [0])
  vignette = Vips::Image.black(image.width, image.height)
  vignette = vignette.draw_circle(128, image.width / 2, image.height / 2, (image.width / 2.2), fill: true)
  sat.composite2(vignette, 'multiply')
end

def golden_hour_glow(image, intensity, _mode, _rng, _meta = {})
  o = Vips::Image.black(image.width, image.height)
  o = o.draw_circle([255, 200, 150], image.width / 2, image.height / 2, (image.width / 3.5), fill: true)
  o = o.gaussblur(25 * intensity * adaptive_scale(image))
  (image + o * 0.35 * intensity).clip(0, 255).cast('uchar')
end

def cross_process(image, intensity, _mode, _rng, _meta = {})
  r, g, b = image.bandsplit
  r = r.linear([1 + 0.15 * intensity], [8 * intensity])
  g = g.linear([1 - 0.1 * intensity], [0])
  b = b.linear([1 + 0.2 * intensity], [-6 * intensity])
  Vips::Image.bandjoin([r, g, b]).cast('uchar')
end

def bloom_effect(image, intensity, _mode, rng, meta = {})
  scale = adaptive_scale(image)
  # Reuse shared highlight mask if provided
  mask = meta[:shared_highlight_mask]
  if mask
    blur = mask.gaussblur((8 * intensity + 2) * scale)
    (image + blur * 0.6 * intensity).clip(0, 255).cast('uchar')
  else
    blur = image.gaussblur((8 * intensity + 2) * scale)
    (image + blur * 0.40 * intensity).clip(0, 255).cast('uchar')
  end
end

def film_halation(image, intensity, _mode, rng, meta = {})
  scale = adaptive_scale(image)
  mask = meta[:shared_highlight_mask]
  if mask
    halo = mask.gaussblur((10 * intensity + 4) * scale).linear(0.12 * intensity, 0)
    halo = halo.bandjoin([halo] * (image.bands - 1)) if halo.bands < image.bands
    (image + halo * 0.6 * intensity).clip(0, 255).cast('uchar')
  else
    thresh = rng.rand(200..235)
    highlights = image > thresh
    halo = highlights.gaussblur((10 * intensity + 4) * scale).linear(0.12 * intensity, 0)
    halo = halo.bandjoin([halo] * (image.bands - 1)) if halo.bands < image.bands
    (image + halo * 0.6 * intensity).clip(0, 255).cast('uchar')
  end
end

def teal_and_orange(image, intensity, _mode, _rng, _meta = {})
  r, g, b = image.bandsplit
  r = r.linear([1 + 0.18 * intensity], [6 * intensity])
  g = g.linear([1 - 0.08 * intensity], [0])
  b = b.linear([1 + 0.10 * intensity], [0])
  Vips::Image.bandjoin([r, g, b]).cast('uchar')
end

def day_for_night(image, intensity, _mode, _rng, _meta = {})
  dark = image.linear([1 - 0.35 * intensity], [-10 * intensity])
  r, g, b = dark.bandsplit
  b = b.linear([1 + 0.15 * intensity], [10 * intensity])
  Vips::Image.bandjoin([r, g, b]).cast('uchar')
end

def anamorphic_simulation(image, intensity, _mode, rng, _meta = {})
  stretch = 1.0 + 0.15 * intensity
  vscale = 1.0 + rng.rand(-0.05..0.05)
  image.resize(stretch, vscale: vscale)
rescue StandardError
  image
end

def chromatic_aberration(image, intensity, _mode, rng, _meta = {})
  shift = (2 * intensity).round
  return image if shift <= 0
  r, g, b = image.bandsplit
  r = r.roll(shift, rng.rand(-shift..shift))
  b = b.roll(-shift, rng.rand(-shift..shift))
  Vips::Image.bandjoin([r, g, b]).cast('uchar')
end

def vhs_degrade(image, intensity, _mode, rng, _meta = {})
  sigma = 25 * intensity + rng.rand(0..15)
  noise = cached_noise(image, sigma)
  noise = noise.bandjoin([noise] * (image.bands - 1)) if noise.bands < image.bands
  lines = Vips::Image.sines(image.width, image.height).linear(0.25 * intensity, 128)
  (image + noise * 0.35 + lines * 0.15).clip(0, 255).cast('uchar')
end

def color_fade(image, intensity, _mode, _rng, _meta = {})
  image.linear([1 - 0.4 * intensity], [35 * intensity]).clip(0, 255).cast('uchar')
end

def film_scratches(image, intensity, _mode, rng, _meta = {})
  count = (5 * intensity).ceil
  overlay = Vips::Image.black(image.width, image.height, bands: image.bands)
  count.times do
    x = rng.rand(0...image.width)
    overlay = overlay.draw_rect([rng.rand(180..255)] * image.bands, x, 0, 1, image.height, fill: true)
  end
  overlay = overlay.gaussblur(2 * adaptive_scale(image))
  (image + overlay * 0.15 * intensity).clip(0, 255).cast('uchar')
end

def film_stock_emulation(image, intensity, _mode, rng, meta = {})
  stock = meta[:stock] || %w[kodak_portra fuji_velvia].sample
  r, g, b = image.bandsplit
  case stock
  when 'kodak_portra'
    r = r.linear([1 + 0.08 * intensity], [8 * intensity])
    g = g.linear([1 - 0.04 * intensity], [0])
    b = b.linear([1 - 0.05 * intensity], [-4 * intensity])
  else # fuji_velvia
    r = r.linear([1 + 0.12 * intensity], [10 * intensity])
    g = g.linear([1 + 0.06 * intensity], [0])
    b = b.linear([1 + 0.04 * intensity], [0])
  end
  Vips::Image.bandjoin([r, g, b]).cast('uchar')
end

# ----------------------------
# Applying Effects
# ----------------------------

def select_random_effects(rng, count, mode)
  keys = EFFECTS.map(&:key)
  if mode == 'experimental'
    exp_keys = keys & EXPERIMENTAL_BIAS_KEYS
    selection = []
    while selection.size < count
      pool = (rng.rand < 0.5 && !exp_keys.empty?) ? exp_keys : keys
      k = rng.sample(pool)
      selection << k unless selection.include?(k)
    end
    selection
  else
    rng.sample(keys, count)
  end
end

def prepare_shared_meta(effects, image, rng)
  keys = effects.map { |e| e[:key] }
  return {} unless keys.include?('film_halation') || keys.include?('bloom_effect')
  # Build one highlight mask; threshold deterministic for reproducibility if seed used
  threshold = 220 # fixed to ensure highlight consistency
  { shared_highlight_mask: (image > threshold) }
end

# Builds effect spec list from recipe

def build_effects_from_recipe(recipe_json, _mode)
  recipe_json.map do |k, v|
    descriptor = EFFECT_INDEX[k.to_s]
    next unless descriptor
    if v.is_a?(Hash)
      intensity = normalize_intensity(v['intensity'] || 0.5)
      meta = v.reject { |ck, _| ck == 'intensity' }.transform_keys(&:to_sym)
    else
      intensity = normalize_intensity(v)
      meta = {}
    end
    { key: descriptor.key, intensity: intensity, meta: meta }
  end.compact
end

def apply_effect_stack(image, effects, mode, rng)
  original_avg = image.avg
  shared_meta = prepare_shared_meta(effects, image, rng)
  effects.each do |eff_spec|
    eff_key = eff_spec[:key]
    intensity = eff_spec[:intensity]
    meta = (eff_spec[:meta] || {}).merge(shared_meta)
    descriptor = EFFECT_INDEX[eff_key]
    next unless descriptor
    impl = descriptor.impl
    begin
      pre_avg = image.avg
      image = send(impl, image, intensity, mode, rng, meta)
      image = image.extract_band(0, n: 3) if image.bands > 3
      delta = (image.avg - pre_avg).round(2)
      $cli_logger.info "Effect #{eff_key} intensity=#{intensity.round(2)} Δavg=#{delta}"
      $logger.debug "Applied #{eff_key} (#{descriptor.category}): #{descriptor.description}"
    rescue StandardError => e
      $logger.error "Effect #{eff_key} failed: #{e.message}"
    end
  end
  total_delta = (image.avg - original_avg).round(2)
  $logger.debug "Total stack Δavg=#{total_delta}"
  image
end

# ----------------------------
# CLI / Input Gathering
# ----------------------------

def gather_inputs
  options = {
    patterns: ['**/*.{jpg,jpeg,png,webp}'],
    mode: nil,
    random: nil,
    variations: 3,
    effect_count: 3,
    seed: nil,
    polish: true,
    recipe_file: nil
  }

  opt = OptionParser.new do |o|
    o.banner = 'Usage: ruby postpro.rb [options]'
    o.on('--professional', 'Professional (subtle) mode') { options[:mode] = 'professional' }
    o.on('--experimental', 'Experimental (bold) mode') { options[:mode] = 'experimental' }
    o.on('--effects N', Integer, 'Effects per variation (default 3)') { |v| options[:effect_count] = v }
    o.on('--variations N', Integer, 'Variations per image (default 3)') { |v| options[:variations] = v }
    o.on('--seed N', Integer, 'Deterministic seed') { |v| options[:seed] = v }
    o.on('--patterns LIST', 'Comma separated glob patterns') { |v| options[:patterns] = v.split(',').map(&:strip) }
    o.on('--recipe FILE', 'JSON recipe file') { |v| options[:recipe_file] = v }
    o.on('--no-random', 'Disable random selection (recipe required)') { options[:random] = false }
    o.on('--no-polish', 'Skip polishing passes') { options[:polish] = false }
    o.on('--help', 'Show help') { puts o; exit }
  end
  
  # Check if this is a CLI-driven run BEFORE parsing (since parsing consumes ARGV)
  cli_mode = ARGV.any? { |arg| arg.start_with?('--') }
  
  opt.parse!(ARGV)

  options[:mode] ||= if cli_mode
                       'professional'  # default for CLI mode
                     else
                       (PROMPT.yes?('Professional mode? (Yes=subtle / No=experimental)', default: true) ? 'professional' : 'experimental')
                     end
  
  # Handle random vs recipe logic
  if options[:recipe_file]
    # Recipe file provided, default to non-random mode
    options[:random] = false if options[:random].nil?
  elsif options[:random] == false
    # --no-random was specified, but no recipe file
    if cli_mode
      options[:recipe_file] = 'recipe.json'  # default
    else
      options[:recipe_file] = PROMPT.ask('Recipe JSON file path:', default: 'recipe.json')
    end
  elsif options[:random].nil?
    # No explicit random choice made
    if cli_mode
      options[:random] = true  # default for CLI mode
    else
      options[:random] = PROMPT.yes?('Apply random effects? (No = load recipe)', default: true)
      unless options[:random]
        options[:recipe_file] = PROMPT.ask('Recipe JSON file path:', default: 'recipe.json')
      end
    end
  end

  if options[:random] != false
    # Only ask for effect count if not already provided and random mode is active
    if !cli_mode && options[:effect_count] == 3  # default value, might need prompting
      options[:effect_count] = PROMPT.ask('Effects per variation (1-8):', default: options[:effect_count].to_s, convert: :int) { |q| q.in('1-8') }
    end
  end
  
  # Only ask for variations if still at default and not in CLI mode
  if !cli_mode && options[:variations] == 3  # default value, might need prompting
    options[:variations] = PROMPT.ask('Variations per image (1-10):', default: options[:variations].to_s, convert: :int) { |q| q.in('1-10') }
  end
  
  # Only ask for patterns if still at default and not in CLI mode
  if !cli_mode && options[:patterns] == ['**/*.{jpg,jpeg,png,webp}']  # default value
    pattern_input = PROMPT.ask('File patterns (comma separated):', default: options[:patterns].join(','))
    options[:patterns] = pattern_input.split(',').map(&:strip)
  end

  options[:seed] ||= (ENV['SEED'] if ENV['SEED']&.match?(/^[0-9]+$/))
  if options[:seed].nil? && PROMPT.yes?('Set deterministic seed?', default: false)
    options[:seed] = PROMPT.ask('Seed (integer):', convert: :int)
  end
  options
end

# ----------------------------
# Processing Pipeline
# ----------------------------

def process_file(path, opts, rng, recipe_effects)
  image = load_image(path)
  orig_avg = image.avg
  processed_count = 0

  opts[:variations].times do |i|
    effects_spec = if recipe_effects
                     recipe_effects
                   else
                     selected_keys = select_random_effects(rng, opts[:effect_count], opts[:mode])
                     selected_keys.map do |k|
                       descriptor = EFFECT_INDEX[k]
                       intensity = choose_intensity(rng, opts[:mode], descriptor.pro_range, descriptor.exp_range)
                       { key: k, intensity: intensity, meta: {} }
                     end
                   end

    variant = apply_effect_stack(image, effects_spec, opts[:mode], rng)

    if opts[:polish]
      polish_sequence = []
      unless effects_spec.any? { |e| e[:key] == 'film_stock_emulation' }
        polish_sequence << { key: 'film_stock_emulation', intensity: choose_intensity(rng, opts[:mode], 0.25..0.55, 0.4..0.9), meta: { stock: %w[kodak_portra fuji_velvia].sample } }
      end
      polish_sequence << { key: 'film_grain', intensity: choose_intensity(rng, opts[:mode], 0.3..0.6, 0.6..1.2), meta: {} }
      polish_sequence << { key: 'film_scratches', intensity: choose_intensity(rng, opts[:mode], 0.2..0.4, 0.5..0.9), meta: {} }
      variant = apply_effect_stack(variant, polish_sequence, opts[:mode], rng)
    end

    final_avg = variant.avg
    delta_total = (final_avg - orig_avg).round(2)
    $logger.warn "Variation change small (Δavg=#{delta_total}) – subtle stack." if delta_total.abs < 5

    ts = Time.now.strftime('%Y%m%d%H%M%S')
    seed_tag = opts[:seed] ? "_s#{opts[:seed]}" : ''
    out = path.sub(File.extname(path), "_processed_v#{i + 1}#{seed_tag}_#{ts}#{File.extname(path)}")
    begin
      variant.write_to_file(out)
      $cli_logger.info "Saved #{out} Δavg=#{delta_total}"
      processed_count += 1
    rescue StandardError => e
      $logger.error "Failed save #{out}: #{e.message}"
    end
  end
  processed_count
rescue StandardError => e
  $logger.error "Failed processing #{path}: #{e.message}"
  0
end

# ----------------------------
# Main
# ----------------------------

def main
  opts = gather_inputs
  rng  = AnalogRNG.new(opts[:seed])

  recipe_effects = nil
  if opts[:recipe_file] && File.exist?(opts[:recipe_file])
    begin
      recipe_json = JSON.parse(File.read(opts[:recipe_file]))
      recipe_effects = build_effects_from_recipe(recipe_json, opts[:mode])
      $cli_logger.info "Loaded recipe with #{recipe_effects.size} effect(s)"
    rescue StandardError => e
      $cli_logger.error "Failed to parse recipe: #{e.message}"
      recipe_effects = nil
    end
  elsif opts[:recipe_file]
    $cli_logger.warn "Recipe file '#{opts[:recipe_file]}' not found; continuing with random selection."
  end

  patterns = opts[:patterns]
  files = patterns.flat_map { |p| Dir.glob(p) }.uniq.reject { |f| f.match?(/_processed_v\d+/) }
  if files.empty?
    $cli_logger.error "No files matched: #{patterns.join(', ')}"
    return
  end

  $cli_logger.info "Mode=#{opts[:mode]} Seed=#{opts[:seed] || 'none'} Variations=#{opts[:variations]} Effects/var=#{opts[:effect_count]} Polish=#{opts[:polish]}"
  start_time = Time.now
  total_variations = 0
  files.each do |f|
    $cli_logger.info "Processing: #{f}"
    total_variations += process_file(f, opts, rng, recipe_effects)
  end
  elapsed = (Time.now - start_time).round(2)
  $cli_logger.info "Completed #{files.size} file(s), #{total_variations} variation(s) in #{elapsed}s"
rescue Interrupt
  $cli_logger.warn 'Interrupted by user.'
rescue StandardError => e
  $cli_logger.error "Fatal: #{e.message}"
  $logger.error e.full_message
end

main if __FILE__ == $0
