#!/usr/bin/env ruby
# frozen_string_literal: true

# Master.json Framework Self-Validation and Testing Suite
# Tests the enhanced v10.2.0 framework against its own standards

require 'json'
require 'yaml'

class MasterJsonValidator
  def initialize(framework_path)
    @framework = JSON.parse(File.read(framework_path))
    @validation_results = {}
    @errors = []
    @warnings = []
  end

  def validate_all
    puts "🔍 Validating Master.json v#{@framework['meta']['version']} Framework..."
    
    validate_json_structure
    validate_norwegian_business_integration
    validate_meta_learning_capabilities
    validate_workflow_intelligence
    validate_architectural_integrity
    validate_cultural_compliance
    validate_innovasjon_norge_integration
    
    print_results
  end

  private

  def validate_json_structure
    print "📋 Validating JSON Structure... "
    
    # Check indentation (must be 2 spaces)
    raw_content = File.read("/home/runner/work/pubhealthcare/pubhealthcare/prompts/master_v10_2_0.json")
    lines = raw_content.split("\n")
    
    lines.each_with_index do |line, index|
      next if line.strip.empty?
      
      indent = line.match(/^(\s*)/)[1]
      if indent.include?("\t")
        add_error("Line #{index + 1}: Contains tabs instead of spaces")
      elsif indent.length % 2 != 0
        add_error("Line #{index + 1}: Incorrect indentation (not multiple of 2 spaces)")
      end
    end
    
    # Check quotes consistency
    if raw_content.include?("'") && raw_content.scan(/"/).length > raw_content.scan(/'/).length
      add_warning("Mixed quote styles detected - should use double quotes consistently")
    end
    
    puts "✅" if @errors.empty?
  end

  def validate_norwegian_business_integration
    print "🇳🇴 Validating Norwegian Business Integration... "
    
    # Check for Norwegian business expert role
    roles = @framework.dig('core', 'multi_perspective', 'roles')
    norwegian_expert = roles&.find { |role| role['role'] == 'norwegian_business_expert' }
    
    if norwegian_expert.nil?
      add_error("Missing 'norwegian_business_expert' role in multi_perspective")
    else
      # Validate Norwegian business expert specializations
      specializations = norwegian_expert['specializations']
      required_specializations = ['innovasjon_norge', 'distrikt_development', 'lagom_culture']
      
      required_specializations.each do |spec|
        unless specializations&.include?(spec)
          add_error("Norwegian business expert missing '#{spec}' specialization")
        end
      end
    end
    
    # Check Innovasjon Norge integration
    innovasjon_norge = @framework.dig('business_strategy', 'norwegian_integration', 'innovasjon_norge')
    if innovasjon_norge.nil?
      add_error("Missing Innovasjon Norge integration in business_strategy")
    else
      funding_categories = innovasjon_norge['funding_categories']
      if funding_categories.nil? || funding_categories.empty?
        add_error("Missing funding categories in Innovasjon Norge integration")
      end
    end
    
    # Check distrikt development
    distrikt = @framework.dig('business_strategy', 'norwegian_integration', 'distrikt_development')
    if distrikt.nil?
      add_error("Missing distrikt development integration")
    end
    
    puts "✅" if @errors.empty?
  end

  def validate_meta_learning_capabilities
    print "🧠 Validating Meta-Learning Capabilities... "
    
    # Check for meta-learning section
    meta_learning = @framework.dig('self_optimization', 'meta_learning')
    if meta_learning.nil?
      add_error("Missing meta_learning section in self_optimization")
    else
      # Validate algorithms
      algorithms = meta_learning['algorithms']
      required_algorithms = ['pattern_recognition', 'self_modification', 'adaptive_optimization']
      
      required_algorithms.each do |alg|
        unless algorithms&.key?(alg)
          add_error("Missing '#{alg}' algorithm in meta_learning")
        end
      end
      
      # Check learning loops
      learning_loops = meta_learning['learning_loops']
      if learning_loops.nil?
        add_error("Missing learning_loops in meta_learning")
      end
      
      # Check architectural integrity preservation
      arch_integrity = meta_learning['architectural_integrity']
      if arch_integrity.nil?
        add_error("Missing architectural_integrity in meta_learning")
      end
    end
    
    puts "✅" if @errors.empty?
  end

  def validate_workflow_intelligence
    print "⚙️  Validating Workflow Intelligence... "
    
    # Check workflow intelligence section
    intelligence = @framework.dig('workflow', 'intelligence')
    if intelligence.nil?
      add_error("Missing intelligence section in workflow")
    else
      # Validate learning loops
      learning_loops = intelligence['learning_loops']
      required_loops = ['success_pattern_recognition', 'failure_analysis', 'workflow_optimization']
      
      required_loops.each do |loop|
        unless learning_loops&.key?(loop)
          add_error("Missing '#{loop}' in workflow intelligence learning_loops")
        end
      end
      
      # Validate adaptive features
      adaptive = intelligence['adaptive_features']
      required_adaptive = ['dynamic_role_weighting', 'context_aware_phase_adjustment']
      
      required_adaptive.each do |feature|
        unless adaptive&.key?(feature)
          add_error("Missing '#{feature}' in workflow intelligence adaptive_features")
        end
      end
    end
    
    puts "✅" if @errors.empty?
  end

  def validate_architectural_integrity
    print "🏗️  Validating Architectural Integrity... "
    
    # Check that core functionality is preserved
    core_sections = ['core', 'workflow', 'stacks', 'quality_assurance', 'security']
    core_sections.each do |section|
      unless @framework.key?(section)
        add_error("Missing core section: #{section}")
      end
    end
    
    # Validate forbidden removals are still forbidden
    forbidden = @framework.dig('self_optimization', 'forbidden_removals')
    required_forbidden = ['security', 'accessibility', 'never_truncate', 'world_class_standards']
    
    required_forbidden.each do |item|
      unless forbidden&.include?(item)
        add_error("Missing forbidden removal protection: #{item}")
      end
    end
    
    # Check that architectural integrity is mentioned in meta_learning
    arch_integrity = @framework.dig('self_optimization', 'meta_learning', 'architectural_integrity')
    if arch_integrity.nil?
      add_error("Missing architectural_integrity preservation in meta_learning")
    end
    
    puts "✅" if @errors.empty?
  end

  def validate_cultural_compliance
    print "🎯 Validating Cultural Compliance... "
    
    # Check lagom principles
    principles = @framework.dig('core', 'principles')
    unless principles&.key?('norwegian_cultural_compliance')
      add_error("Missing norwegian_cultural_compliance in core principles")
    end
    
    # Check cultural compliance in business strategy
    cultural = @framework.dig('business_strategy', 'norwegian_integration', 'cultural_compliance')
    if cultural.nil?
      add_error("Missing cultural_compliance in Norwegian integration")
    else
      unless cultural.key?('lagom_principles')
        add_error("Missing lagom_principles in cultural_compliance")
      end
    end
    
    # Check Norwegian design elements
    design_principles = @framework.dig('design_system', 'principles')
    unless design_principles&.include?('lagom_simplicity')
      add_error("Missing lagom_simplicity in design_system principles")
    end
    
    puts "✅" if @errors.empty?
  end

  def validate_innovasjon_norge_integration
    print "🚀 Validating Innovasjon Norge Integration... "
    
    # Check funding categories
    funding_categories = @framework.dig('business_strategy', 'norwegian_integration', 'innovasjon_norge', 'funding_categories')
    expected_categories = ['innovative_projects', 'business_development', 'research_development']
    
    expected_categories.each do |category|
      unless funding_categories&.include?(category)
        add_error("Missing funding category: #{category}")
      end
    end
    
    # Check quality gate for Innovasjon Norge readiness
    gates = @framework.dig('quality_assurance', 'gates')
    unless gates&.key?('innovasjon_norge_readiness')
      add_error("Missing innovasjon_norge_readiness quality gate")
    end
    
    # Check success metrics
    success_metrics = @framework.dig('self_optimization', 'success_metrics')
    unless success_metrics&.key?('norwegian_business_success')
      add_error("Missing norwegian_business_success metric")
    end
    
    puts "✅" if @errors.empty?
  end

  def add_error(message)
    @errors << message
    puts "❌"
  end

  def add_warning(message)
    @warnings << message
    puts "⚠️"
  end

  def print_results
    puts "\n" + "="*60
    puts "VALIDATION RESULTS"
    puts "="*60
    
    if @errors.empty? && @warnings.empty?
      puts "🎉 ALL VALIDATIONS PASSED! Master.json v#{@framework['meta']['version']} is ready for deployment."
    else
      puts "❌ VALIDATION ISSUES FOUND:"
      
      if @errors.any?
        puts "\nERRORS:"
        @errors.each { |error| puts "  • #{error}" }
      end
      
      if @warnings.any?
        puts "\nWARNINGS:"
        @warnings.each { |warning| puts "  • #{warning}" }
      end
    end
    
    puts "\nFRAMEWORK ENHANCEMENT SUMMARY:"
    enhancements = @framework.dig('meta', 'enhancement_log', 0, 'improvements')
    if enhancements
      enhancements.each { |enhancement| puts "  ✅ #{enhancement}" }
    end
    
    puts "\nNORWEGIAN BUSINESS INTEGRATION:"
    puts "  🇳🇴 Norwegian Business Expert Role: #{@framework.dig('core', 'multi_perspective', 'roles')&.find { |r| r['role'] == 'norwegian_business_expert' } ? '✅' : '❌'}"
    puts "  🏢 Innovasjon Norge Integration: #{@framework.dig('business_strategy', 'norwegian_integration', 'innovasjon_norge') ? '✅' : '❌'}"
    puts "  🌍 Distrikt Development Support: #{@framework.dig('business_strategy', 'norwegian_integration', 'distrikt_development') ? '✅' : '❌'}"
    puts "  🎯 Cultural Compliance (Lagom): #{@framework.dig('business_strategy', 'norwegian_integration', 'cultural_compliance', 'lagom_principles') ? '✅' : '❌'}"
    
    puts "\nMETA-LEARNING CAPABILITIES:"
    puts "  🧠 Pattern Recognition: #{@framework.dig('self_optimization', 'meta_learning', 'algorithms', 'pattern_recognition') ? '✅' : '❌'}"
    puts "  🔄 Self-Modification: #{@framework.dig('self_optimization', 'meta_learning', 'algorithms', 'self_modification') ? '✅' : '❌'}"
    puts "  ⚙️  Adaptive Optimization: #{@framework.dig('self_optimization', 'meta_learning', 'algorithms', 'adaptive_optimization') ? '✅' : '❌'}"
    puts "  🏗️  Architectural Integrity: #{@framework.dig('self_optimization', 'meta_learning', 'architectural_integrity') ? '✅' : '❌'}"
    
    puts "="*60
  end
end

# Run validation
if __FILE__ == $0
  validator = MasterJsonValidator.new("/home/runner/work/pubhealthcare/pubhealthcare/prompts/master_v10_2_0.json")
  validator.validate_all
end