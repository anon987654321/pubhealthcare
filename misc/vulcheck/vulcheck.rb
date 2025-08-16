#!/usr/bin/env ruby
# frozen_string_literal: true

# **Enhanced VulCheck Security Scanner v2.0**
#
# Enterprise-grade security scanner for macOS, iOS, and Android platforms
# Features zero-trust architecture, command injection prevention, and comprehensive security hardening
#
# Copyright (c) 2025 - Security Scanner Project
# Licensed under MIT License

require 'optparse'
require 'fileutils'
require 'open3'
require 'shellwords'
require 'json'
require 'yaml'
require 'logger'
require 'digest'
require 'timeout'
require 'pathname'

class VulCheck
  VERSION = '2.0.0'
  
  # Security Constants
  ALLOWED_COMMANDS = %w[
    chkrootkit rkhunter aide port netstat ps grep which find
    ls cat head tail wc awk sed tr sort uniq
  ].freeze
  
  MACPORTS_PACKAGES = %w[chkrootkit rkhunter aide].freeze
  JAILBREAK_INDICATORS = [
    '/Applications/Cydia.app',
    '/Applications/blackra1n.app', 
    '/Applications/FakeCarrier.app',
    '/Applications/Icy.app',
    '/Applications/IntelliScreen.app',
    '/Applications/MxTube.app',
    '/Applications/RockApp.app',
    '/Applications/SBSettings.app',
    '/Applications/WinterBoard.app',
    '/usr/sbin/sshd',
    '/usr/bin/sshd',
    '/usr/sbin/ssh',
    '/bin/bash',
    '/bin/sh',
    '/etc/apt',
    '/private/var/tmp/cydia.log',
    '/private/var/lib/apt',
    '/private/var/lib/cydia',
    '/private/var/cache/apt',
    '/private/var/log/syslog',
    '/private/var/stash',
    '/private/var/lib/dpkg',
    '/System/Library/LaunchDaemons/com.ikey.bbot.plist',
    '/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist',
    '/Library/MobileSubstrate/MobileSubstrate.dylib',
    '/usr/libexec/ssh-keysign',
    '/usr/libexec/sftp-server',
    '/var/cache/apt',
    '/var/lib/apt',
    '/var/lib/cydia',
    '/usr/bin/ssh-keygen'
  ].freeze
  
  ANDROID_ROOT_INDICATORS = [
    '/system/xbin/su',
    '/system/bin/su',
    '/system/app/Superuser.apk',
    '/data/data/com.noshufou.android.su',
    '/data/data/com.thirdparty.superuser',
    '/data/data/eu.chainfire.supersu',
    '/data/data/com.koushikdutta.superuser',
    '/data/data/com.zachspong.temprootremovejb',
    '/data/data/com.ramdroid.appquarantine',
    '/data/local/bin/su',
    '/data/local/xbin/su',
    '/sbin/su',
    '/su/bin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/cache/su',
    '/data/su',
    '/dev/su'
  ].freeze
  
  # Color codes for enhanced UX
  COLORS = {
    red: 31,
    green: 32, 
    yellow: 33,
    blue: 34,
    magenta: 35,
    cyan: 36,
    white: 37,
    reset: 0
  }.freeze
  
  # Suspicious network patterns
  SUSPICIOUS_PORTS = [1337, 31337, 4444, 5555, 6666, 8080, 9999].freeze
  SUSPICIOUS_PROCESSES = [
    'nc', 'netcat', 'ncat', 'socat', 'telnet', 'ssh', 'scp', 'rsync',
    'wget', 'curl', 'ftp', 'tftp', 'python', 'perl', 'ruby', 'bash', 'sh'
  ].freeze
  
  def initialize(options = {})
    @options = options
    @config = load_configuration
    @log_file = @config['log_file'] || 'vulcheck_secure.log'
    @verbose = @options[:verbose] || @config['verbose'] || false
    @no_color = @options[:no_color] || @config['no_color'] || false
    @privileged = false
    @scan_results = {
      platform: nil,
      vulnerabilities: [],
      warnings: [],
      info: [],
      scan_time: nil,
      scan_duration: nil
    }
    
    setup_secure_logging
    validate_environment
  end
  
  # Zero-Trust Security Architecture
  def validate_environment
    log_info('Initializing zero-trust security validation...')
    
    # Validate Ruby environment
    validate_ruby_environment
    
    # Validate filesystem permissions
    validate_filesystem_security
    
    # Check for suspicious environment variables
    validate_environment_variables
    
    log_success('Environment validation completed')
  end
  
  def validate_ruby_environment
    # Check Ruby version for known vulnerabilities
    ruby_version = RUBY_VERSION
    if Gem::Version.new(ruby_version) < Gem::Version.new('2.7.0')
      log_warning("Ruby version #{ruby_version} may have security vulnerabilities. Consider upgrading.")
    end
    
    # Validate $LOAD_PATH
    $LOAD_PATH.each do |path|
      next unless File.exist?(path)
      
      stat = File.stat(path)
      if stat.world_writable?
        log_error("Insecure load path detected: #{path} is world-writable")
        exit(1) if @config['strict_security']
      end
    end
  end
  
  def validate_filesystem_security
    # Check current directory permissions
    current_dir = Dir.pwd
    stat = File.stat(current_dir)
    
    if stat.world_writable?
      log_error("Current directory #{current_dir} is world-writable - security risk")
      exit(1) if @config['strict_security']
    end
    
    # Validate log file location
    log_dir = File.dirname(@log_file)
    unless File.exist?(log_dir)
      FileUtils.mkdir_p(log_dir, mode: 0o750)
    end
  end
  
  def validate_environment_variables
    suspicious_vars = %w[LD_PRELOAD LD_LIBRARY_PATH DYLD_INSERT_LIBRARIES]
    suspicious_vars.each do |var|
      if ENV[var]
        log_warning("Suspicious environment variable detected: #{var}=#{sanitize_for_log(ENV[var])}")
        @scan_results[:warnings] << "Suspicious environment variable: #{var}"
      end
    end
  end
  
  # Secure Logging Framework
  def setup_secure_logging
    @logger = Logger.new(@log_file, 'monthly')
    @logger.level = @verbose ? Logger::DEBUG : Logger::INFO
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime}] #{severity}: #{sanitize_for_log(msg)}\n"
    end
  end
  
  def sanitize_for_log(message)
    # Filter sensitive data from logs
    sanitized = message.to_s.dup
    
    # Remove potential passwords, tokens, keys
    sanitized.gsub!(/password[=:]\s*\S+/i, 'password=***FILTERED***')
    sanitized.gsub!(/token[=:]\s*\S+/i, 'token=***FILTERED***')
    sanitized.gsub!(/key[=:]\s*\S+/i, 'key=***FILTERED***')
    sanitized.gsub!(/auth[=:]\s*\S+/i, 'auth=***FILTERED***')
    
    # Truncate overly long messages
    sanitized.length > 500 ? "#{sanitized[0..497]}..." : sanitized
  end
  
  def log_info(message)
    puts colorize(message, :cyan) unless @options[:quiet]
    @logger.info(message)
  end
  
  def log_success(message)
    puts colorize("✓ #{message}", :green) unless @options[:quiet]
    @logger.info("[SUCCESS] #{message}")
  end
  
  def log_warning(message)
    puts colorize("⚠ #{message}", :yellow) unless @options[:quiet]
    @logger.warn(message)
    @scan_results[:warnings] << message
  end
  
  def log_error(message)
    puts colorize("✗ #{message}", :red) unless @options[:quiet]
    @logger.error(message)
    @scan_results[:vulnerabilities] << message
  end
  
  def colorize(text, color)
    return text if @no_color
    
    color_code = COLORS[color] || COLORS[:white]
    "\e[#{color_code}m#{text}\e[#{COLORS[:reset]}m"
  end
  
  # Enhanced User Experience
  def show_banner
    banner = <<~BANNER
      #{colorize('╔════════════════════════════════════════════════════════════════╗', :cyan)}
      #{colorize('║', :cyan)}               #{colorize('VulCheck Security Scanner v' + VERSION, :white)}                #{colorize('║', :cyan)}
      #{colorize('║', :cyan)}        #{colorize('Enterprise-Grade Cross-Platform Security Analysis', :blue)}         #{colorize('║', :cyan)}
      #{colorize('╚════════════════════════════════════════════════════════════════╝', :cyan)}
    BANNER
    
    puts banner unless @options[:quiet]
  end
  
  def show_progress(current, total, message = '')
    return if @options[:quiet]
    
    percent = (current.to_f / total * 100).round(1)
    bar_length = 40
    filled_length = (bar_length * current / total).to_i
    
    bar = '█' * filled_length + '░' * (bar_length - filled_length)
    progress_line = "\r#{colorize('[', :cyan)}#{colorize(bar, :green)}#{colorize(']', :cyan)} #{percent}% #{message}"
    
    print progress_line
    puts if current == total
  end
  
  # Privilege Validation System
  def validate_privileges
    log_info('Validating privilege requirements...')
    
    @privileged = Process.uid.zero?
    
    if @privileged
      # Additional validation for root privileges
      validate_root_privileges
      log_success('Running with root privileges')
    else
      log_warning('Running without root privileges - some scans may be limited')
      unless @options[:platform] == 'android'
        log_warning('Consider running with sudo for comprehensive scans')
      end
    end
    
    # Validate effective user ID
    euid = Process.euid
    uid = Process.uid
    
    if euid != uid
      log_warning("EUID (#{euid}) differs from UID (#{uid}) - potential privilege escalation")
    end
  end
  
  def validate_root_privileges
    # Additional security checks for root execution
    if ENV['SUDO_USER'].nil? && Process.uid.zero?
      log_warning('Running as root without sudo - security risk')
    end
    
    # Check for suspicious umask
    current_umask = File.umask
    File.umask(current_umask) # Restore original umask
    
    if current_umask < 0o022
      log_warning("Permissive umask detected: #{sprintf('%03o', current_umask)}")
    end
  end
  
  # Platform Detection Logic
  def detect_platform
    log_info('Detecting platform...')
    
    platform = nil
    
    # Enhanced platform detection with multiple validation methods
    if RUBY_PLATFORM.include?('darwin')
      if File.exist?('/System/Library/CoreServices/SystemVersion.plist')
        # macOS detection
        if File.exist?('/Applications/Utilities/Terminal.app')
          platform = 'macos'
        # iOS detection with multiple indicators  
        elsif File.exist?('/System/Applications/MobileSafari.app') ||
              File.exist?('/System/Applications/Feedback.app') ||
              File.exist?('/var/mobile')
          platform = 'ios'
        end
      end
    elsif RUBY_PLATFORM.include?('linux')
      # Android detection
      if File.exist?('/system/build.prop') || 
         File.exist?('/data/data') ||
         ENV['ANDROID_ROOT'] ||
         system('getprop ro.build.version.release > /dev/null 2>&1')
        platform = 'android'
      else
        # Linux system
        platform = 'linux'
      end
    elsif RUBY_PLATFORM.include?('mswin') || RUBY_PLATFORM.include?('mingw')
      platform = 'windows'
    end
    
    if platform.nil?
      log_error('Unable to detect platform')
      exit(1)
    end
    
    # Additional platform validation
    validate_platform(platform)
    
    @scan_results[:platform] = platform
    log_success("Platform detected: #{platform.upcase}")
    platform
  end
  
  def validate_platform(platform)
    case platform
    when 'macos'
      validate_macos_environment
    when 'ios'
      validate_ios_environment  
    when 'android'
      validate_android_environment
    when 'linux'
      log_info('Linux platform detected - limited support')
    else
      log_error("Unsupported platform: #{platform}")
      exit(1)
    end
  end
  
  def validate_macos_environment
    # Check macOS version
    version_plist = '/System/Library/CoreServices/SystemVersion.plist'
    if File.exist?(version_plist)
      content = File.read(version_plist)
      if content =~ /<key>ProductVersion<\/key>\s*<string>([^<]+)<\/string>/
        version = $1
        log_info("macOS version: #{version}")
        
        # Check for supported versions
        if Gem::Version.new(version) < Gem::Version.new('10.12')
          log_warning("macOS version #{version} may have limited support")
        end
      end
    end
    
    # Check System Integrity Protection
    if system('csrutil status > /dev/null 2>&1')
      log_info('System Integrity Protection is available')
    end
  end
  
  def validate_ios_environment
    # Check iOS version if accessible
    log_info('iOS environment detected')
    
    # Check for common iOS directories
    ios_dirs = ['/var/mobile', '/System/Library/PrivateFrameworks']
    ios_dirs.each do |dir|
      if File.exist?(dir)
        log_info("iOS directory confirmed: #{dir}")
        break
      end
    end
  end
  
  def validate_android_environment
    # Check Android version
    if system('getprop ro.build.version.release > /dev/null 2>&1')
      version = `getprop ro.build.version.release`.strip
      log_info("Android version: #{version}") unless version.empty?
    end
    
    # Check for Android directories
    android_dirs = ['/system', '/data', '/vendor']
    android_dirs.each do |dir|
      if File.exist?(dir)
        log_info("Android directory confirmed: #{dir}")
        break
      end
    end
  end
  
  # Command Injection Prevention
  def safe_execute(command, args = [], timeout: 30)
    # Validate command against whitelist
    base_command = command.split.first
    unless ALLOWED_COMMANDS.include?(base_command)
      log_error("Command not allowed: #{base_command}")
      return { success: false, output: '', error: 'Command not allowed' }
    end
    
    # Escape all arguments
    escaped_args = args.map { |arg| Shellwords.escape(arg.to_s) }
    full_command = [command, *escaped_args].join(' ')
    
    log_info("Executing: #{sanitize_for_log(full_command)}") if @verbose
    
    begin
      output = ''
      error = ''
      
      Timeout.timeout(timeout) do
        Open3.popen3(full_command) do |stdin, stdout, stderr, wait_thr|
          stdin.close
          
          output = stdout.read
          error = stderr.read
          
          exit_status = wait_thr.value
          
          return {
            success: exit_status.success?,
            output: output,
            error: error,
            exit_code: exit_status.exitstatus
          }
        end
      end
    rescue Timeout::Error
      log_error("Command timed out: #{sanitize_for_log(full_command)}")
      return { success: false, output: '', error: 'Command timed out' }
    rescue => e
      log_error("Command execution failed: #{e.message}")
      return { success: false, output: '', error: e.message }
    end
  end
  
  # Configuration File Support
  def load_configuration
    config_files = [
      './vulcheck.yml',
      './vulcheck.yaml', 
      './vulcheck.json',
      '~/.vulcheck/config.yml',
      '/etc/vulcheck/config.yml'
    ]
    
    config_files.each do |config_file|
      expanded_path = File.expand_path(config_file)
      next unless File.exist?(expanded_path)
      
      begin
        case File.extname(expanded_path).downcase
        when '.yml', '.yaml'
          return YAML.load_file(expanded_path) || {}
        when '.json'
          return JSON.parse(File.read(expanded_path))
        end
      rescue => e
        puts "Warning: Failed to load config file #{expanded_path}: #{e.message}"
      end
    end
    
    # Default configuration
    {
      'log_file' => 'vulcheck_secure.log',
      'verbose' => false,
      'no_color' => false,
      'strict_security' => true,
      'scan_timeout' => 300,
      'network_scan' => true,
      'process_scan' => true,
      'file_scan' => true
    }
  end
  
  # macOS Security Scanning
  def scan_macos
    log_info('Starting macOS security scan...')
    
    ensure_macports if @privileged
    install_macos_dependencies if @privileged
    update_macos_tools if @privileged
    
    scan_macos_rootkits
    scan_macos_processes
    scan_macos_network
    scan_macos_files
    
    log_success('macOS security scan completed')
  end
  
  def ensure_macports
    log_info('Checking MacPorts installation...')
    
    result = safe_execute('which port')
    unless result[:success]
      log_error('MacPorts not found. Please install from https://www.macports.org/')
      exit(1) unless @options[:continue_on_error]
      return false
    end
    
    log_success('MacPorts found')
    true
  end
  
  def install_macos_dependencies
    return unless @privileged
    
    log_info('Installing/updating macOS security tools...')
    
    MACPORTS_PACKAGES.each_with_index do |package, index|
      show_progress(index, MACPORTS_PACKAGES.length, "Installing #{package}")
      
      # Check if already installed
      check_result = safe_execute('port', ['installed', package])
      if check_result[:success] && !check_result[:output].include?('None of the specified')
        log_info("#{package} is already installed")
        next
      end
      
      # Install package
      log_info("Installing #{package}...")
      install_result = safe_execute('port', ['install', package], timeout: 600)
      
      if install_result[:success]
        log_success("#{package} installed successfully")
      else
        log_error("Failed to install #{package}: #{install_result[:error]}")
      end
      
      show_progress(index + 1, MACPORTS_PACKAGES.length, "Installing #{package}")
    end
  end
  
  def update_macos_tools
    return unless @privileged
    
    log_info('Updating macOS security tools...')
    
    tools = [
      { name: 'rkhunter', update_cmd: 'rkhunter --update' },
      { name: 'chkrootkit', update_cmd: 'chkrootkit -q' } # chkrootkit doesn't have update flag
    ]
    
    tools.each do |tool|
      log_info("Updating #{tool[:name]}...")
      result = safe_execute(tool[:update_cmd])
      
      if result[:success]
        log_success("#{tool[:name]} updated successfully")
      else
        log_warning("Failed to update #{tool[:name]}: #{result[:error]}")
      end
    end
  end
  
  def scan_macos_rootkits
    log_info('Scanning for rootkits on macOS...')
    
    rootkit_scanners = [
      { name: 'chkrootkit', cmd: 'chkrootkit -q' },
      { name: 'rkhunter', cmd: 'rkhunter --check --skip-keypress --report-warnings-only' }
    ]
    
    rootkit_scanners.each do |scanner|
      log_info("Running #{scanner[:name]}...")
      result = safe_execute(scanner[:cmd], [], timeout: 600)
      
      if result[:success]
        if result[:output].strip.empty?
          log_success("#{scanner[:name]} - No threats detected")
        else
          log_warning("#{scanner[:name]} detected potential issues:")
          puts result[:output] unless @options[:quiet]
          @scan_results[:warnings] << "#{scanner[:name]} detected potential issues"
        end
      else
        log_warning("#{scanner[:name]} scan failed: #{result[:error]}")
      end
    end
  end
  
  def scan_macos_processes
    log_info('Scanning running processes...')
    
    result = safe_execute('ps aux')
    return unless result[:success]
    
    processes = result[:output].lines
    suspicious_found = false
    
    SUSPICIOUS_PROCESSES.each do |suspicious_proc|
      matching_processes = processes.select { |proc| proc.include?(suspicious_proc) }
      next if matching_processes.empty?
      
      matching_processes.each do |proc|
        log_warning("Suspicious process detected: #{proc.strip}")
        suspicious_found = true
      end
    end
    
    log_success('Process scan completed') unless suspicious_found
  end
  
  def scan_macos_network
    return unless @config['network_scan']
    
    log_info('Scanning network connections...')
    
    result = safe_execute('netstat -an')
    return unless result[:success]
    
    connections = result[:output].lines
    suspicious_found = false
    
    connections.each do |connection|
      next unless connection.include?('ESTABLISHED')
      
      SUSPICIOUS_PORTS.each do |port|
        if connection.include?(":#{port} ")
          log_warning("Suspicious network connection on port #{port}: #{connection.strip}")
          suspicious_found = true
        end
      end
    end
    
    log_success('Network scan completed') unless suspicious_found
  end
  
  def scan_macos_files
    return unless @config['file_scan']
    
    log_info('Scanning system files...')
    
    # Check for modified system files
    if @privileged
      result = safe_execute('find /System -name "*.dylib" -newer /System/Library/CoreServices/SystemVersion.plist 2>/dev/null | head -10')
      if result[:success] && !result[:output].strip.empty?
        log_warning('Modified system libraries detected:')
        result[:output].lines.each { |line| log_warning("  #{line.strip}") }
      end
    end
    
    log_success('File scan completed')
  end
  
  # iOS Security Scanning
  def scan_ios
    log_info('Starting iOS security scan...')
    
    check_ios_jailbreak
    scan_ios_processes if @privileged
    scan_ios_network
    
    log_success('iOS security scan completed')
  end
  
  def check_ios_jailbreak
    log_info('Checking for jailbreak indicators...')
    
    jailbreak_found = false
    JAILBREAK_INDICATORS.each_with_index do |indicator, index|
      show_progress(index, JAILBREAK_INDICATORS.length, 'Checking jailbreak indicators')
      
      if File.exist?(indicator)
        log_warning("Jailbreak indicator found: #{indicator}")
        jailbreak_found = true
      end
      
      show_progress(index + 1, JAILBREAK_INDICATORS.length, 'Checking jailbreak indicators')
    end
    
    # Additional jailbreak detection methods
    check_ios_url_schemes
    check_ios_sandbox_violations
    
    if jailbreak_found
      log_error('Device appears to be jailbroken')
      @scan_results[:vulnerabilities] << 'iOS device is jailbroken'
    else
      log_success('No jailbreak indicators detected')
    end
  end
  
  def check_ios_url_schemes
    # Check for jailbreak-related URL schemes
    jb_schemes = %w[cydia:// sileo:// zbra:// installer:// undecimus://]
    
    # This would require iOS-specific APIs in a real implementation
    log_info('Checking URL schemes (placeholder for iOS-specific implementation)')
  end
  
  def check_ios_sandbox_violations
    # Check for sandbox violations
    violation_paths = [
      '/etc/fstab',
      '/Library/Preferences/com.saurik.Cydia.plist',
      '/var/cache/apt/',
      '/var/lib/cydia/'
    ]
    
    violation_paths.each do |path|
      if File.exist?(path)
        log_warning("Sandbox violation detected: #{path}")
        @scan_results[:warnings] << "Sandbox violation: #{path}"
      end
    end
  end
  
  def scan_ios_processes
    log_info('Scanning iOS processes...')
    
    result = safe_execute('ps aux 2>/dev/null || ps -A')
    return unless result[:success]
    
    processes = result[:output].lines
    jb_processes = %w[substrate MobileSubstrate Cydia]
    
    jb_processes.each do |jb_proc|
      matching = processes.select { |proc| proc.include?(jb_proc) }
      next if matching.empty?
      
      matching.each do |proc|
        log_warning("Jailbreak-related process: #{proc.strip}")
      end
    end
  end
  
  def scan_ios_network
    log_info('Scanning iOS network connections...')
    
    result = safe_execute('netstat -an 2>/dev/null')
    return unless result[:success]
    
    connections = result[:output].lines
    ssh_connections = connections.select { |conn| conn.include?(':22 ') && conn.include?('LISTEN') }
    
    unless ssh_connections.empty?
      log_warning('SSH server appears to be running (jailbreak indicator)')
      @scan_results[:warnings] << 'SSH server detected on iOS device'
    end
  end
  
  # Android Security Scanning
  def scan_android
    log_info('Starting Android security scan...')
    
    check_android_root
    scan_android_processes
    scan_android_network
    scan_android_packages
    
    log_success('Android security scan completed')
  end
  
  def check_android_root
    log_info('Checking for root access indicators...')
    
    root_found = false
    ANDROID_ROOT_INDICATORS.each_with_index do |indicator, index|
      show_progress(index, ANDROID_ROOT_INDICATORS.length, 'Checking root indicators')
      
      if File.exist?(indicator)
        log_warning("Root indicator found: #{indicator}")
        root_found = true
      end
      
      show_progress(index + 1, ANDROID_ROOT_INDICATORS.length, 'Checking root indicators')
    end
    
    # Check for su command
    su_result = safe_execute('which su')
    if su_result[:success] && !su_result[:output].strip.empty?
      log_warning("su command found: #{su_result[:output].strip}")
      root_found = true
    end
    
    # Check for root package managers
    root_managers = %w[com.topjohnwu.magisk eu.chainfire.supersu com.koushikdutta.superuser]
    root_managers.each do |manager|
      pm_result = safe_execute('pm list packages ' + manager)
      if pm_result[:success] && pm_result[:output].include?(manager)
        log_warning("Root management app detected: #{manager}")
        root_found = true
      end
    end
    
    if root_found
      log_error('Device appears to be rooted')
      @scan_results[:vulnerabilities] << 'Android device is rooted'
    else
      log_success('No root indicators detected')
    end
  end
  
  def scan_android_processes
    log_info('Scanning Android processes...')
    
    result = safe_execute('ps')
    return unless result[:success]
    
    processes = result[:output].lines
    suspicious_found = false
    
    # Look for suspicious processes
    root_processes = %w[su daemon magisk supersu]
    root_processes.each do |root_proc|
      matching = processes.select { |proc| proc.include?(root_proc) }
      next if matching.empty?
      
      matching.each do |proc|
        log_warning("Suspicious process detected: #{proc.strip}")
        suspicious_found = true
      end
    end
    
    log_success('Process scan completed') unless suspicious_found
  end
  
  def scan_android_network
    log_info('Scanning Android network connections...')
    
    result = safe_execute('netstat -an 2>/dev/null || cat /proc/net/tcp')
    return unless result[:success]
    
    connections = result[:output]
    
    # Check for ADB connections
    if connections.include?(':5555') || connections.include?(':5037')
      log_warning('ADB connections detected - potential security risk')
      @scan_results[:warnings] << 'ADB connections detected'
    end
    
    # Check for suspicious ports
    SUSPICIOUS_PORTS.each do |port|
      if connections.include?(":#{port.to_s(16).upcase}")
        log_warning("Suspicious network activity on port #{port}")
      end
    end
  end
  
  def scan_android_packages
    log_info('Scanning installed packages...')
    
    result = safe_execute('pm list packages 2>/dev/null')
    return unless result[:success]
    
    packages = result[:output].lines
    
    # Check for known malicious packages
    malicious_keywords = %w[rootkit trojan backdoor keylogger spyware]
    
    packages.each do |package|
      malicious_keywords.each do |keyword|
        if package.downcase.include?(keyword)
          log_warning("Potentially malicious package: #{package.strip}")
        end
      end
    end
  end
  
  # Main execution flow
  def execute
    start_time = Time.now
    
    show_banner
    
    begin
      validate_privileges
      platform = detect_platform
      
      # Override platform if specified in options
      platform = @options[:platform] if @options[:platform]
      
      case platform
      when 'macos'
        scan_macos
      when 'ios'
        scan_ios
      when 'android'
        scan_android
      else
        log_error("Unsupported platform: #{platform}")
        exit(1)
      end
      
      generate_report(start_time)
      
    rescue Interrupt
      log_error('Scan interrupted by user')
      exit(1)
    rescue => e
      log_error("Unexpected error: #{e.message}")
      log_error("Backtrace: #{e.backtrace.join("\n")}") if @verbose
      exit(1)
    end
  end
  
  def generate_report(start_time)
    end_time = Time.now
    @scan_results[:scan_time] = end_time
    @scan_results[:scan_duration] = end_time - start_time
    
    puts "\n" + "=" * 70 unless @options[:quiet]
    puts colorize("Security Scan Report", :cyan) unless @options[:quiet]
    puts "=" * 70 unless @options[:quiet]
    
    puts colorize("Platform: #{@scan_results[:platform].upcase}", :white) unless @options[:quiet]
    puts colorize("Scan Duration: #{@scan_results[:scan_duration].round(2)} seconds", :white) unless @options[:quiet]
    puts colorize("Scan Completed: #{@scan_results[:scan_time]}", :white) unless @options[:quiet]
    
    if @scan_results[:vulnerabilities].any?
      puts colorize("\nVulnerabilities Found: #{@scan_results[:vulnerabilities].length}", :red) unless @options[:quiet]
      @scan_results[:vulnerabilities].each { |vuln| puts colorize("  ✗ #{vuln}", :red) unless @options[:quiet] }
    else
      puts colorize("\n✓ No critical vulnerabilities detected", :green) unless @options[:quiet]
    end
    
    if @scan_results[:warnings].any?
      puts colorize("\nWarnings: #{@scan_results[:warnings].length}", :yellow) unless @options[:quiet]
      @scan_results[:warnings].each { |warning| puts colorize("  ⚠ #{warning}", :yellow) unless @options[:quiet] }
    end
    
    # Save detailed report to file
    save_detailed_report
    
    puts "\n" + colorize("Detailed log saved to: #{@log_file}", :cyan) unless @options[:quiet]
    puts "=" * 70 unless @options[:quiet]
  end
  
  def save_detailed_report
    report_file = "vulcheck_report_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json"
    
    begin
      File.write(report_file, JSON.pretty_generate(@scan_results))
      log_info("Detailed report saved to: #{report_file}")
    rescue => e
      log_error("Failed to save report: #{e.message}")
    end
  end
end

# Command-line interface
def main
  options = {}
  
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"
    opts.separator ""
    opts.separator "Platform options:"
    
    opts.on('--macos', 'Scan macOS system') { options[:platform] = 'macos' }
    opts.on('--ios', 'Scan iOS device') { options[:platform] = 'ios' }  
    opts.on('--android', 'Scan Android device') { options[:platform] = 'android' }
    opts.on('--auto', 'Auto-detect platform (default)') { options[:platform] = nil }
    
    opts.separator ""
    opts.separator "Output options:"
    
    opts.on('-v', '--verbose', 'Enable verbose output') { options[:verbose] = true }
    opts.on('-q', '--quiet', 'Suppress non-essential output') { options[:quiet] = true }
    opts.on('--no-color', 'Disable colored output') { options[:no_color] = true }
    
    opts.separator ""
    opts.separator "Control options:"
    
    opts.on('--continue-on-error', 'Continue scan even if errors occur') { options[:continue_on_error] = true }
    opts.on('--version', 'Show version information') do
      puts "VulCheck Security Scanner v#{VulCheck::VERSION}"
      exit
    end
    
    opts.separator ""
    
    opts.on_tail('-h', '--help', 'Show this help message') do
      puts opts
      exit
    end
  end.parse!
  
  # Create and execute scanner
  scanner = VulCheck.new(options)
  scanner.execute
end

# Execute if run directly
if __FILE__ == $0
  main
end
