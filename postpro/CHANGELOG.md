# Changelog

All notable changes to Postpro.rb will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [13.4.0] - 2025-08-14

### Added
- **Professional vs Experimental Mode System**: Two distinct creative modes with different intensity ranges
  - Professional: subtle, film-adjacent aesthetic (0.2-0.8 typical ranges)
  - Experimental: bold, stylized, extreme analog artifacts (0.5-2.0+ ranges)
- **AnalogRNG Deterministic Wrapper**: Centralized RNG for reproducible results
  - `--seed` CLI flag for deterministic processing
  - `SEED` environment variable support
  - Identical seed + inputs = identical outputs (except timestamps)
- **Effect Registry with Metadata**: Structured effect definitions with:
  - Categories (texture, light, optical, color, contrast, degrade)
  - Descriptions for each effect
  - Per-mode intensity ranges (professional vs experimental)
  - Implementation method references
- **Enhanced JSON Recipe Support**:
  - Simple numeric intensities: `"film_grain": 0.6`
  - Advanced metadata form: `"film_stock_emulation": {"intensity": 0.5, "stock": "kodak_portra"}`
  - Graceful fallback to random mode on parse errors
- **Optional Polishing Pipeline**: 
  - Automatic film_stock_emulation + film_grain + film_scratches finishing
  - `--no-polish` flag to disable
  - Smart detection to avoid duplicate film_stock_emulation
- **Performance Optimizations**:
  - Shared highlight mask reuse between bloom_effect and film_halation
  - Noise field cache for grain & VHS degrade effects
  - Adaptive blur scaling for small images (<1024px) to prevent oversoftening
- **Enhanced CLI Interface**:
  - `--professional` / `--experimental` mode flags
  - `--effects N` for effect count per variation
  - `--variations N` for variations per image
  - `--seed N` for deterministic processing
  - `--patterns LIST` for file pattern specification
  - `--recipe FILE` for JSON recipe loading
  - `--no-random` to enforce recipe-only mode
  - `--no-polish` to skip polishing pipeline
- **Improved Logging & Monitoring**:
  - Per-effect Δavg (average intensity change) logging
  - Total stack delta reporting
  - Graceful error handling with pipeline continuation
  - Enhanced debug logging with effect categories
- **Image Normalization & Resilience**:
  - Automatic grayscale → sRGB conversion
  - Alpha channel stripping for 3-band processing
  - Effect failure isolation (individual effects can fail without stopping pipeline)
  - Intensity clamping to [0.0, 5.0] range

### Changed
- **Complete Engine Rewrite**: Replaced simple effect application with structured pipeline
- **Effect Method Signatures**: All effects now accept `(image, intensity, mode, rng, meta = {})`
- **Effect Selection Logic**: Professional mode uses balanced selection; Experimental biases toward dramatic effects
- **File Naming**: Added seed tags and timestamps for better variation tracking
- **Configuration**: Interactive prompts now include mode selection and seed options

### Enhanced Effects
- **film_grain**: Now uses cached noise generation for performance
- **light_leaks**: Mode-dependent count and color variation
- **bloom_effect**: Adaptive blur scaling and shared highlight mask support
- **film_halation**: Shared highlight mask optimization, deterministic thresholds
- **lens_distortion**: Improved error handling and graceful fallbacks
- **chromatic_aberration**: Enhanced band shifting with random variance
- **vhs_degrade**: Cached noise reuse and enhanced scanline simulation
- **golden_hour_glow**: Adaptive scaling for consistent effect across image sizes
- **cross_process**: Improved color channel manipulation
- **film_stock_emulation**: Support for Kodak Portra and Fuji Velvia style curves
- **film_scratches**: New effect for vertical emulsion damage simulation

### Fixed
- Consistent error handling across all effects
- Memory efficiency improvements through caching
- Color space normalization for diverse input formats
- Band count handling for various image types

### Performance
- Reduced memory usage through noise caching
- Eliminated duplicate highlight mask computations
- Adaptive processing for different image sizes
- Streaming processing maintained through libvips

### Dependencies
- libvips >= 8.14.x (previously >= 8.10.x)
- ruby-vips gem (maintained)
- tty-prompt gem (maintained)
- json gem (standard library)
- optparse gem (standard library)

## [13.3.x] - Legacy Versions
- Simple effect application without structured pipeline
- Basic JSON recipe support
- Limited CLI options

## [12.x.x] - Legacy Versions  
- Initial libvips integration
- Basic effect implementations
- Simple batch processing

---

## Migration from 13.3.x

The v13.4.0 upgrade is a complete rewrite. Key migration considerations:

1. **CLI Changes**: Update any automation scripts to use new flag syntax
2. **Effect Method Signatures**: Custom effects need signature updates
3. **Recipe Format**: Enhanced JSON format is backward compatible for simple numeric values
4. **Output Naming**: New timestamp and seed tag format in output filenames
5. **Dependencies**: Verify libvips version >= 8.14.x

## Future Roadmap

- [ ] Parallel batch processor with deterministic sub-seed derivation
- [ ] Golden image regression tests with visual hash comparison
- [ ] Real benchmark data collection and integration
- [ ] Additional mask reuse optimizations
- [ ] GPU acceleration exploration for compute-intensive effects