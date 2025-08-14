# Postpro.rb – Filmic & Analog Post-Processing Engine (v13.4.0)

Version: 13.4.0  
Updated: 2025-08-14  
Author: PubHealthcare  

---

## Purpose

Postpro.rb is a high‑performance, libvips‑powered image post‑processing engine delivering layered analog and cinematic transformations. It is designed as an open, scriptable alternative to fixed in‑camera "film simulation" / "creative style" systems provided by camera manufacturers (e.g., Fuji, Sony, Canon, Nikon).  
It does not replicate proprietary vendor looks; instead it offers a modular, reproducible, extensible pipeline for building your own aesthetic.

---

## Why This vs In‑Camera / OEM Simulations

| Dimension | Postpro.rb | Typical In‑Camera Simulation (Fuji/Sony/etc.) |
|-----------|------------|-----------------------------------------------|
| Extensibility | Add / edit Ruby effects, full source available | Fixed firmware presets |
| Randomization | Per‑run stochastic layers (optional deterministic seed) | Deterministic, single recipe |
| Layer Depth | Multi-stage: optical, chemical, film, mechanical & artifact domains | Color & tone curves + limited grain |
| Batch Processing | Recursive, multi-variation generation | Single frame at capture time |
| Reproducibility | Seeded mode (exact recreation) | Vendor-defined, not user-seeded |
| Open Source | Yes | No |
| Performance (24MP reference) | Parallelizable libvips core (see benchmarks) | N/A (in-camera hardware pipeline) |

Trademarks belong to their respective owners—comparisons are nominative and purely feature-scoped.

---

## Core Capabilities

1. Dual Creative Modes  
   - Professional: restrained, film-adjacent subtlety  
   - Experimental: bold, stylized, glitch or extreme analog artifacts  
2. Layered Analog Domains  
   - Texture: grain, scratches  
   - Optical: aberration, lens distortion, anamorphic stretch, halation, bloom  
   - Chemical / Emulsion: stock bias (Portra / Velvia style tonal math)  
   - Mechanical / Media: VHS, tape wear  
   - Grading: teal/orange, cross-process, day-for-night, sepia, color fade, lomo  
3. Deterministic Reproducibility  
   - Set a seed (flag or env var) to recreate exact multi‑effect outcomes  
4. Recipes + Random Hybrid  
   - Provide a JSON recipe with fixed intensities, or allow stochastic selection per variation  
5. High Performance  
   - Built on libvips (streaming / low memory)  
   - Shared highlight mask reuse for bloom & halation  
   - Noise cache for grain & VHS degrade (reduced recomputation)  

---

## Quick Start

Install libvips and gems:

```bash
# macOS
brew install vips
# Debian/Ubuntu
sudo apt-get install -y libvips
# OpenBSD
doas pkg_add -U vips

gem install --user-install ruby-vips tty-prompt
```

Run:

```bash
ruby postpro/postpro.rb
```

Example interactive answers:
```
Professional mode? Yes
Apply random effects? Yes
Effects per variation: 3
Variations per image: 4
Set deterministic seed? No
File patterns: images/**/*.{jpg,jpeg,png}
```

Deterministic run:

```bash
ruby postpro/postpro.rb --professional --effects 4 --variations 2 --seed 123 --patterns "images/*.jpg"
```

Using a recipe only:

```bash
ruby postpro/postpro.rb --recipe myrecipe.json --no-random
```

---

## JSON Recipe Format

Simple numeric intensities:

```json
{
  "film_grain": 0.6,
  "bloom_effect": 0.8,
  "teal_and_orange": 0.5
}
```

Advanced with metadata:

```json
{
  "film_stock_emulation": { "intensity": 0.5, "stock": "kodak_portra" },
  "film_grain": 0.4,
  "film_scratches": { "intensity": 0.3 }
}
```

---

## CLI Flags

| Flag | Description | Default |
|------|-------------|---------|
| --professional / --experimental | Mode selection | Prompt |
| --effects N | Effects per variation (random mode) | 3 |
| --variations N | Variations per input image | 3 |
| --seed N | Deterministic seed | none |
| --patterns LIST | Comma-separated globs | **/*.{jpg,jpeg,png,webp} |
| --recipe FILE | Use fixed JSON recipe | none |
| --no-random | Enforce recipe-only execution | false |
| --no-polish | Skip auto film_stock + grain + scratches finishing | false |

---

## Effect Matrix (Representative)

| Effect Key | Category | Professional Range | Experimental Range | Notes |
|------------|----------|--------------------|--------------------|-------|
| film_grain | texture | 0.2–0.8 | 0.5–2.0 | Gaussian noise fused; shared cache |
| film_scratches | texture | 0.2–0.6 | 0.5–1.2 | Thin vertical lines, blurred |
| light_leaks | light | 0.2–0.6 | 0.5–1.5 | Warm circular additive overlays |
| bloom_effect | light | 0.3–0.8 | 0.7–1.8 | Reuses highlight mask when halation present |
| film_halation | light | 0.2–0.6 | 0.5–1.2 | Shared highlight mask; blur scaled |
| lens_distortion | optical | 0.1–0.3 | 0.3–0.9 | Identity warp approximation |
| chromatic_aberration | optical | 0.2–0.5 | 0.6–1.5 | Band splitting + roll shifts |
| anamorphic_simulation | optical | 0.2–0.5 | 0.4–1.0 | Horizontal stretch & vertical variance |
| vhs_degrade | degrade | 0.2–0.6 | 0.7–1.6 | Noise + sine line overlays (cached noise) |
| bleach_bypass | contrast | 0.3–0.7 | 0.6–1.4 | Luma blend + contrast lift |
| teal_and_orange | color | 0.3–0.7 | 0.6–1.4 | Split warm/cool contrasts |
| cross_process | color | 0.2–0.7 | 0.6–1.5 | Non-linear channel bias |
| day_for_night | color | 0.2–0.6 | 0.5–1.2 | Darken + blue channel boost |
| sepia | color | 0.2–0.6 | 0.5–1.2 | Standard recombination matrix |
| lomo | color | 0.3–0.7 | 0.6–1.5 | Saturation + soft vignette |
| golden_hour_glow | light | 0.2–0.6 | 0.5–1.2 | Warm gaussian core (adaptive scaling) |
| film_stock_emulation | color | 0.2–0.6 | 0.4–1.0 | Portra/Velvia tonal curves |
| color_fade | color | 0.2–0.6 | 0.5–1.2 | Global fade & offset |

---

## Determinism & Reproducibility

- Central RNG (AnalogRNG) seeds all stochastic decisions.  
- Same seed + inputs + flags => identical effect selection, intensities, and ordering (filenames differ only by timestamp).  
- Filenames include seed tag for correlation.  
- For fully static outputs in CI, patch timestamp generation.

---

## Performance Optimizations

1. **Shared Highlight Mask**: Bloom & halation share one threshold mask computation.  
2. **Noise Cache**: Grain & VHS degrade reuse gaussnoise() of matching dimensions.  
3. **Adaptive Blur Scale**: Small images get proportionally smaller blur radius to avoid oversoften.  
4. **Streaming libvips**: Minimal memory, high throughput for large images.

---

## Edge Cases & Resilience

- **Effect Failure**: Individual effect errors logged but pipeline continues.  
- **Invalid JSON**: Non-parsing recipes fall back to random mode.  
- **Small Images**: Adaptive scaling ensures effects remain visible on <1024px images.  
- **Grayscale Input**: Auto-conversion to sRGB; alpha channels stripped.  
- **Intensity Clamping**: Values outside [0, 5] range clamped to prevent mathematical issues.

---

## Extending Effects

Add to EFFECTS array in postpro.rb:

```ruby
Effect.new('my_effect', :my_effect_impl, 'category', 'Description', 0.1..0.5, 0.3..1.0)
```

Implement method with signature:

```ruby
def my_effect_impl(image, intensity, mode, rng, meta = {})
  # Apply transformations
  # Return Vips::Image
end
```

---

## Legal & Trademark Notice

Camera manufacturer trademarks (Fuji, Sony, Canon, Nikon, Kodak, etc.) belong to their respective owners. This software provides independent analog-style image transformations and does not replicate, reverse-engineer, or infringe upon proprietary film simulation recipes or color science. Comparisons are made for educational and feature-scoping purposes under fair use.

---

## Changelog (Extract)

**v13.4.0** (2025-08-14):
- Professional vs Experimental mode system
- AnalogRNG deterministic wrapper  
- Effect registry with metadata & intensity ranges
- Shared highlight mask optimization
- Adaptive blur scaling for small images
- Noise cache for performance
- Enhanced CLI with --seed, --professional, --recipe flags
- Polishing pipeline toggle
- Per-effect delta logging

**v13.3.x**: Legacy simple effect application  
**v12.x**: Basic libvips integration  

---

## Benchmarks

*Placeholder: Real performance data to be inserted after collection across test hardware configurations.*

---

**Repository**: https://github.com/anon987654321/pub  
**License**: Creative Commons / Open Source (see repository)  
**Support**: Issues via GitHub or discussion forums