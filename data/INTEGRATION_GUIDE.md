# Dataset & Prompt Library Integration Guide

## Overview
This guide describes the new dataset structure for Concepts 4-30 and how to integrate it with the existing postpro.rb system.

## Dataset Structure

### Core Files
- `data/concepts_master.json` - Complete concept definitions with prompts and metadata
- `data/additional_concepts.json` - Reference file for concepts 21-30
- `data/taxonomy.yaml` - Hierarchical organization and cross-references
- `data/postpro_recipes.json` - Extended post-processing recipes for all concepts

### File Descriptions

#### concepts_master.json
- Contains all 27 concepts (IDs 4-30)
- Each concept includes:
  - Core prompts and full base prompts
  - Camera, lens, and lighting modules
  - Professional postpro stacks
  - Experimental notes
  - Categorization tags

#### postpro_recipes.json
- Professional and experimental postpro stacks
- Effect definitions and usage notes
- Cross-referenced with concept slugs
- Compatible with existing postpro.rb

#### taxonomy.yaml
- Hierarchical organization by domain, lighting, camera, aesthetics
- Technical approach categories
- Complexity levels (beginner to expert)
- Cross-references validate against master concepts

## Integration with postpro.rb

### Loading Extended Recipes
```ruby
require 'json'

# Load the extended recipe collection
recipes = JSON.parse(File.read('data/postpro_recipes.json'))

# Access concept-specific recipes
concept = 'biomimetic-growth'
professional_stack = recipes['concept_recipes'][concept]['professional']
experimental_stack = recipes['concept_recipes'][concept]['experimental']
```

### Example Usage
```ruby
# Load a specific concept's professional recipe
concept_slug = 'neuroplastic-rhythm-garden'
recipe = recipes['concept_recipes'][concept_slug]['professional']

# Apply the recipe
recipe.each do |effect, intensity|
  apply_effect(effect, intensity)
end
```

## CI/CD Integration

### GitHub Actions Workflow
The `dataset-validation.yml` workflow provides:
- JSON/YAML syntax validation
- Concept data integrity checks
- Postpro recipe cross-reference validation
- Taxonomy cross-reference validation
- Ruby postpro.rb smoke tests

### Running Validation Locally
```bash
# Run comprehensive validation
python3 comprehensive_validation.py

# Run specific dataset validation steps
python3 -m json.tool data/concepts_master.json > /dev/null
python3 -c "import yaml; yaml.safe_load(open('data/taxonomy.yaml'))"
```

## Usage Examples

### Concept Discovery
```python
import json

# Load concepts
with open('data/concepts_master.json', 'r') as f:
    concepts = json.load(f)

# Find concepts by tag
macro_concepts = [c for c in concepts['concepts'] if 'macro' in c['tags']]
print(f"Found {len(macro_concepts)} macro photography concepts")
```

### Recipe Selection
```python
# Load recipes
with open('data/postpro_recipes.json', 'r') as f:
    recipes = json.load(f)

# Get all experimental recipes with high bloom effects
high_bloom = {}
for concept, recipe in recipes['concept_recipes'].items():
    if 'experimental' in recipe:
        bloom = recipe['experimental'].get('bloom_effect', 0)
        if bloom > 0.8:
            high_bloom[concept] = bloom

print(f"High bloom concepts: {list(high_bloom.keys())}")
```

### Taxonomy Navigation
```python
import yaml

# Load taxonomy
with open('data/taxonomy.yaml', 'r') as f:
    taxonomy = yaml.safe_load(f)

# Find all cinematic concepts
cinematic = taxonomy['hierarchy']['domain']['cinematic']
print(f"Cinematic concepts: {cinematic}")
```

## Integration Points

### With Existing Systems
1. **postpro.rb**: Loads JSON recipes directly
2. **comprehensive_validation.py**: Extended with dataset validation
3. **GitHub Actions**: Automated validation on changes

### Future Extensions
1. Add new concepts by extending concepts_master.json
2. Create new postpro effects and update recipes
3. Extend taxonomy with new categorizations
4. Add marketing caption generation

## Validation Checklist

Before committing changes:
- [ ] JSON files pass syntax validation
- [ ] YAML files pass syntax validation
- [ ] Concept IDs are complete and sequential
- [ ] All concepts have postpro recipes
- [ ] Taxonomy references are valid
- [ ] postpro.rb can load new recipes
- [ ] CI workflow passes all tests

## File Sizes and Statistics
- concepts_master.json: ~27KB, 27 concepts
- additional_concepts.json: ~1KB, 10 concept references
- taxonomy.yaml: ~6KB, hierarchical organization
- postpro_recipes.json: ~14KB, 54 recipe stacks (27×2)

## License and Attribution
Prompts & metadata © respective author; redistribute with attribution.
Model usage: Swap or combine modules; keep negative prompt for cleanliness.