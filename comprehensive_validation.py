#!/usr/bin/env python3
"""
Comprehensive Integration Validation Script

This script validates that all components of the repository are properly integrated
and working together as expected for the comprehensive pull request.
"""

import json
import os
import sys
from pathlib import Path

def validate_json_file(filepath, description):
    """Validate that a JSON file is valid and return its data."""
    try:
        with open(filepath, 'r') as f:
            data = json.load(f)
        print(f"  ✅ {description}: Valid JSON ({len(json.dumps(data))} bytes)")
        return data
    except FileNotFoundError:
        print(f"  ❌ {description}: File not found - {filepath}")
        return None
    except json.JSONDecodeError as e:
        print(f"  ❌ {description}: Invalid JSON - {e}")
        return None
    except Exception as e:
        print(f"  ❌ {description}: Error - {e}")
        return None

def check_cross_references(data, filepath):
    """Check for @ref: cross-references in JSON data."""
    content = json.dumps(data)
    ref_count = content.count('@ref:')
    if ref_count > 0:
        print(f"    📎 Found {ref_count} cross-references")
    return ref_count

def validate_framework_components():
    """Validate all framework components."""
    print("🔍 Validating Framework Components:")
    
    # Main configurations
    main_config = validate_json_file('prompts.json', 'Main Configuration (v38)')
    v37_config = validate_json_file('prompts-v37.json', 'Modular Engine (v37)')
    
    if not main_config or not v37_config:
        return False
    
    # Check versions
    main_version = main_config.get('meta', {}).get('version', 'unknown')
    v37_version = v37_config.get('meta', {}).get('version', 'unknown')
    print(f"    📊 Main version: {main_version}, V37 version: {v37_version}")
    
    # Check consolidation features
    features = main_config.get('meta', {}).get('consolidation_summary', {}).get('features_added', [])
    print(f"    🎯 Consolidated features: {len(features)}")
    
    return True

def validate_modular_system():
    """Validate the modular plugin system."""
    print("\n🔍 Validating Modular System:")
    
    # Check modules directory
    modules_path = Path('modules')
    if not modules_path.exists():
        print("  ❌ Modules directory not found")
        return False
    
    expected_modules = [
        'behavioral-rules.json',
        'universal-standards.json', 
        'workflow-engine.json',
        'quality-gates.json'
    ]
    
    modules_valid = True
    for module_file in expected_modules:
        module_path = modules_path / module_file
        data = validate_json_file(module_path, f"Module: {module_file}")
        if not data:
            modules_valid = False
        else:
            check_cross_references(data, module_path)
    
    # Check plugins directory
    plugins_path = Path('plugins')
    if not plugins_path.exists():
        print("  ❌ Plugins directory not found")
        return False
    
    expected_plugins = [
        'web-development.json',
        'design-system.json',
        'business-strategy.json',
        'ai-enhancement.json'
    ]
    
    for plugin_file in expected_plugins:
        plugin_path = plugins_path / plugin_file
        data = validate_json_file(plugin_path, f"Plugin: {plugin_file}")
        if not data:
            modules_valid = False
        else:
            check_cross_references(data, plugin_path)
    
    return modules_valid

def validate_rails_application():
    """Validate the Rails application structure."""
    print("\n🔍 Validating Rails Application:")
    
    rails_app_path = Path('brgen_app')
    if not rails_app_path.exists():
        print("  ❌ Rails application directory not found")
        return False
    
    # Check key Rails files
    key_files = [
        'Gemfile',
        'config/routes.rb',
        'app/models/user.rb',
        'app/controllers/application_controller.rb'
    ]
    
    rails_valid = True
    for file_path in key_files:
        full_path = rails_app_path / file_path
        if full_path.exists():
            print(f"  ✅ Rails file: {file_path}")
        else:
            print(f"  ❌ Rails file missing: {file_path}")
            rails_valid = False
    
    # Check test directory
    test_path = rails_app_path / 'test'
    if test_path.exists():
        test_files = list(test_path.rglob('*.rb'))
        print(f"  ✅ Test suite: {len(test_files)} test files")
    else:
        print("  ❌ Test directory not found")
        rails_valid = False
    
    return rails_valid

def validate_documentation():
    """Validate that documentation is comprehensive."""
    print("\n🔍 Validating Documentation:")
    
    doc_files = [
        'COMPREHENSIVE_INTEGRATION_REPORT.md',
        'CONSOLIDATION_SUMMARY.md',
        'FRAMEWORK_V37_VALIDATION_REPORT.md',
        'MASTER_FRAMEWORK_V37_INTEGRATION_GUIDE.md',
        'BEFORE_AFTER_COMPARISON.md',
        'REFACTORING_SUMMARY.md'
    ]
    
    docs_valid = True
    for doc_file in doc_files:
        if Path(doc_file).exists():
            size = Path(doc_file).stat().st_size
            print(f"  ✅ Documentation: {doc_file} ({size} bytes)")
        else:
            print(f"  ❌ Documentation missing: {doc_file}")
            docs_valid = False
    
    return docs_valid

def validate_rails_directory():
    """Validate Rails directory structure."""
    print("\n🔍 Validating Rails Directory Structure:")
    
    rails_path = Path('rails')
    if not rails_path.exists():
        print("  ❌ Rails directory not found")
        return False
    
    # Check for brgen subdirectory
    brgen_path = rails_path / 'brgen'
    if brgen_path.exists():
        brgen_files = list(brgen_path.glob('*.sh'))
        print(f"  ✅ BRGEN scripts: {len(brgen_files)} shell scripts")
    else:
        print("  ❌ BRGEN directory not found")
        return False
    
    return True

def validate_dataset_integration():
    """Validate the new dataset components."""
    print("🔍 Validating Dataset Integration:")
    
    # Check data directory exists
    if not os.path.exists('data'):
        print("  ❌ Data directory not found")
        return False
    
    # Validate required dataset files
    required_files = [
        'data/concepts_master.json',
        'data/additional_concepts.json', 
        'data/taxonomy.yaml',
        'data/postpro_recipes.json'
    ]
    
    missing_files = []
    for file_path in required_files:
        if not os.path.exists(file_path):
            missing_files.append(file_path)
        else:
            # Validate JSON/YAML syntax
            try:
                if file_path.endswith('.json'):
                    with open(file_path, 'r') as f:
                        json.load(f)
                elif file_path.endswith('.yaml'):
                    import yaml
                    with open(file_path, 'r') as f:
                        yaml.safe_load(f)
                print(f"  ✅ {file_path}: Valid and accessible")
            except Exception as e:
                print(f"  ❌ {file_path}: Invalid format - {e}")
                return False
    
    if missing_files:
        print(f"  ❌ Missing dataset files: {missing_files}")
        return False
    
    # Validate concept data integrity
    try:
        with open('data/concepts_master.json', 'r') as f:
            master_data = json.load(f)
        
        concept_ids = [concept['id'] for concept in master_data['concepts']]
        expected_ids = list(range(4, 31))
        
        if set(concept_ids) != set(expected_ids):
            missing = set(expected_ids) - set(concept_ids)
            extra = set(concept_ids) - set(expected_ids)
            print(f"  ❌ Concept ID mismatch. Missing: {missing}, Extra: {extra}")
            return False
        
        print(f"  ✅ All concept IDs 4-30 present ({len(concept_ids)} concepts)")
    except Exception as e:
        print(f"  ❌ Failed to validate concept integrity: {e}")
        return False
    
    # Validate postpro recipes integration
    try:
        with open('data/postpro_recipes.json', 'r') as f:
            recipes_data = json.load(f)
        
        concept_slugs = [concept['slug'] for concept in master_data['concepts']]
        recipe_slugs = list(recipes_data['concept_recipes'].keys())
        
        missing_recipes = set(concept_slugs) - set(recipe_slugs)
        if missing_recipes:
            print(f"  ❌ Missing recipes for concepts: {missing_recipes}")
            return False
        
        print(f"  ✅ All {len(concept_slugs)} concepts have postpro recipes")
    except Exception as e:
        print(f"  ❌ Failed to validate postpro recipes: {e}")
        return False
    
    return True

def main():
    """Main validation function."""
    print("🚀 Comprehensive Integration Validation")
    print("=" * 50)
    
    validations = [
        validate_framework_components(),
        validate_modular_system(),
        validate_rails_application(),
        validate_rails_directory(),
        validate_documentation(),
        validate_dataset_integration()
    ]
    
    print("\n📊 Validation Summary:")
    print("=" * 30)
    
    if all(validations):
        print("✅ ALL VALIDATIONS PASSED")
        print("🎉 Repository is fully integrated and ready for comprehensive PR")
        return 0
    else:
        failed_count = validations.count(False)
        print(f"❌ {failed_count}/{len(validations)} validations failed")
        print("🔧 Please address the issues above before finalizing the PR")
        return 1

if __name__ == "__main__":
    sys.exit(main())