# VulCheck Quick Reference Guide

## Quick Start Commands

```bash
# Basic scans
sudo ruby vulcheck.rb --macos         # Full macOS scan
ruby vulcheck.rb --ios               # iOS jailbreak check  
ruby vulcheck.rb --android           # Android root check
ruby vulcheck.rb --auto              # Auto-detect platform

# Advanced options
ruby vulcheck.rb --macos --verbose    # Detailed output
ruby vulcheck.rb --android --quiet    # Minimal output
ruby vulcheck.rb --ios --no-color     # No colors (for logs)
```

## Configuration Files

### Priority Order
1. `./vulcheck.yml` (current directory)
2. `./vulcheck.json` (current directory)  
3. `~/.vulcheck/config.yml` (user home)
4. `/etc/vulcheck/config.yml` (system-wide)

### Example Config
```yaml
log_file: "/var/log/vulcheck/security.log"
verbose: false
strict_security: true
scan_timeout: 600
network_scan: true
process_scan: true
file_scan: true
```

## Output Files

- `vulcheck_secure.log` - Main log file
- `vulcheck_report_YYYYMMDD_HHMMSS.json` - Detailed JSON report
- Custom log file (if configured)

## Security Features

### Zero-Trust Architecture
- ✅ Input validation and sanitization
- ✅ Command whitelisting (only approved commands)
- ✅ Environment variable validation  
- ✅ Privilege escalation detection

### Command Injection Prevention
- ✅ Shellwords.escape() for all arguments
- ✅ Timeout protection for all commands
- ✅ Command execution logging
- ✅ Error handling and graceful degradation

### Secure Logging
- ✅ Automatic filtering of sensitive data
- ✅ Structured logging with severity levels
- ✅ Configurable log retention
- ✅ Optional encryption support

## Platform-Specific Features

### macOS
- Rootkit detection (chkrootkit, rkhunter, aide)
- MacPorts integration
- System Integrity Protection awareness
- Network and process monitoring

### iOS  
- 25+ jailbreak indicators
- Sandbox violation detection
- SSH server detection
- URL scheme checking

### Android
- Multi-vector root detection
- Package analysis
- ADB connection monitoring
- Root management app detection

## Troubleshooting

### Common Issues
```bash
# MacPorts not found
export PATH=/opt/local/bin:/opt/local/sbin:$PATH

# Permission denied
sudo ruby vulcheck.rb --macos

# Ruby version too old
ruby --version  # Should be 2.7.0+

# Command timeouts
echo 'scan_timeout: 900' > vulcheck.yml
```

### Performance Optimization
```yaml
# Fast scan configuration
scan_timeout: 120
file_scan: false
network_scan: false
process_scan: true
```

### Debug Mode
```bash
ruby vulcheck.rb --macos --verbose 2>&1 | tee debug.log
```

## Enterprise Deployment

### Service Account Setup
```bash
sudo useradd -r -s /bin/false vulcheck
sudo mkdir -p /var/log/vulcheck
sudo chown vulcheck:vulcheck /var/log/vulcheck
sudo chmod 750 /var/log/vulcheck
```

### Cron Integration
```bash
# Daily security scan at 2 AM
0 2 * * * /usr/bin/ruby /opt/vulcheck/vulcheck.rb --auto --quiet
```

### SIEM Integration
```bash
# Splunk
ruby vulcheck.rb --quiet --no-color | splunk add oneshot

# ELK Stack  
ruby vulcheck.rb --json | curl -X POST "elastic:9200/security/_doc" -H 'Content-Type: application/json' -d @-
```

## Exit Codes

- `0` - Scan completed successfully
- `1` - Critical error or vulnerability found
- `2` - Configuration error
- `3` - Platform not supported
- `130` - Interrupted by user (Ctrl+C)

## Log Levels

- `ERROR` - Critical issues requiring immediate attention
- `WARN` - Potential security concerns  
- `INFO` - Normal operation messages
- `DEBUG` - Detailed execution information (verbose mode)

## Support

- Documentation: See vulcheck.md for complete guide
- Issues: Report via GitHub Issues
- Security: security@vulcheck-project.org
- Version: `ruby vulcheck.rb --version`