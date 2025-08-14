# Package Distribution Documentation

**Date:** January 22, 2025  
**Project:** Laravel Zero validate-links Documentation Enhancement  
**Phase:** Package Distribution Documentation

## Executive Summary

This document provides comprehensive documentation for distributing the validate-links Laravel Zero application through multiple channels including Packagist.org, binary distribution, and various installation methods. It covers the complete publishing process, maintenance procedures, and update strategies.

## Distribution Overview

The validate-links application supports multiple distribution methods:

1. **Composer Package** - Via Packagist.org for PHP developers
2. **PHAR Binary** - Standalone executable via Box
3. **GitHub Releases** - Tagged releases with assets
4. **Direct Installation** - Git clone and local setup

## Packagist.org Publishing Process

### Package Configuration

#### Composer Package Metadata
```json
{
    "name": "s-a-c/validate-links",
    "description": "Comprehensive PHP Link Validation and Remediation Tools - Laravel Zero Edition",
    "type": "project",
    "keywords": ["link-validation", "documentation", "laravel-zero", "cli"],
    "license": "MIT",
    "authors": [
        {
            "name": "StandAloneComplex",
            "email": "71233932+s-a-c@users.noreply.github.com"
        }
    ],
    "bin": ["validate-links"]
}
```

#### Package Requirements
- **PHP Version:** ^8.4
- **Extensions:** ext-json, ext-mbstring, ext-curl
- **Framework:** Laravel Zero ^12.0
- **Type:** Project (not library)

### Publishing Workflow

#### Initial Package Registration
```bash
# 1. Ensure package is ready for publication
composer validate
composer install --no-dev
composer test

# 2. Create initial release tag
git tag -a v1.0.0 -m "Initial release"
git push origin v1.0.0

# 3. Submit to Packagist.org
# Visit https://packagist.org/packages/submit
# Enter repository URL: https://github.com/s-a-c/validate-links
# Click "Check" and then "Submit"
```

#### Automated Publishing via GitHub Actions
```yaml
name: Publish to Packagist

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: 8.4

      - name: Validate Composer
        run: composer validate --strict

      - name: Install Dependencies
        run: composer install --no-dev --optimize-autoloader

      - name: Run Tests
        run: composer test

      - name: Update Packagist
        run: |
          curl -XPOST -H'content-type:application/json' \
               'https://packagist.org/api/update-package?username=${{ secrets.PACKAGIST_USERNAME }}&apiToken=${{ secrets.PACKAGIST_TOKEN }}' \
               -d'{"repository":{"url":"https://packagist.org/packages/s-a-c/validate-links"}}'
```

### Semantic Versioning Strategy

#### Version Format: MAJOR.MINOR.PATCH

**MAJOR (X.0.0):**
- Breaking changes to CLI interface
- Incompatible API changes
- Major architecture changes
- PHP version requirement changes

**MINOR (0.X.0):**
- New features and commands
- New configuration options
- Performance improvements
- Backward-compatible changes

**PATCH (0.0.X):**
- Bug fixes
- Security patches
- Documentation updates
- Minor improvements

#### Pre-release Versions
- **Alpha:** `1.0.0-alpha.1` - Early development
- **Beta:** `1.0.0-beta.1` - Feature complete, testing
- **RC:** `1.0.0-rc.1` - Release candidate

#### Version Tagging Process
```bash
# 1. Update version in relevant files
# Update composer.json version (if applicable)
# Update application version constant

# 2. Create and push tag
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3

# 3. Create GitHub release
# Use GitHub web interface or CLI
gh release create v1.2.3 --title "Version 1.2.3" --notes "Release notes..."
```

## Binary Distribution (PHAR)

### Box Configuration (`box.json`)

```json
{
    "chmod": "0755",
    "directories": [
        "app",
        "bootstrap", 
        "config",
        "vendor"
    ],
    "files": [
        "composer.json"
    ],
    "exclude-composer-files": false,
    "compression": "GZ",
    "compactors": [
        "KevinGH\\Box\\Compactor\\Php",
        "KevinGH\\Box\\Compactor\\Json"
    ],
    "main": "validate-links",
    "output": "validate-links.phar",
    "stub": true
}
```

### Binary Build Process

#### Manual Build
```bash
# 1. Install Box globally
composer global require humbug/box

# 2. Prepare for build
composer install --no-dev --optimize-autoloader
composer dump-autoload --optimize --classmap-authoritative

# 3. Build PHAR
box compile

# 4. Test binary
./validate-links.phar --version
./validate-links.phar validate --help

# 5. Verify binary integrity
box verify validate-links.phar
```

#### Automated Build via GitHub Actions
```yaml
name: Build Binary

on:
  release:
    types: [published]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: 8.4
          tools: composer:v2

      - name: Install Dependencies
        run: composer install --no-dev --optimize-autoloader

      - name: Install Box
        run: composer global require humbug/box

      - name: Build PHAR
        run: box compile

      - name: Test Binary
        run: |
          ./validate-links.phar --version
          ./validate-links.phar validate --help

      - name: Upload Binary to Release
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ github.event.release.upload_url }}
          asset_path: ./validate-links.phar
          asset_name: validate-links.phar
          asset_content_type: application/octet-stream
```

### Binary Optimization

#### Size Optimization
```json
{
    "exclude-dev-files": true,
    "exclude-composer-files": true,
    "prune": true,
    "exclude": [
        "tests/",
        "docs/",
        ".github/",
        "*.md",
        "phpunit.xml*",
        "pest.config.php"
    ]
}
```

#### Performance Optimization
```bash
# Enable OPcache for better performance
php -d opcache.enable_cli=1 validate-links.phar

# Use JIT compilation (PHP 8.0+)
php -d opcache.jit_buffer_size=100M validate-links.phar
```

## Installation Methods

### 1. Composer Global Installation
```bash
# Install globally via Composer
composer global require s-a-c/validate-links

# Ensure global Composer bin is in PATH
export PATH="$PATH:$HOME/.composer/vendor/bin"

# Use the command
validate-links --version
```

### 2. Composer Project Installation
```bash
# Install in specific project
composer require s-a-c/validate-links

# Use via vendor/bin
./vendor/bin/validate-links --version
```

### 3. PHAR Binary Installation
```bash
# Download latest PHAR
curl -L -o validate-links.phar https://github.com/s-a-c/validate-links/releases/latest/download/validate-links.phar

# Make executable
chmod +x validate-links.phar

# Move to system PATH (optional)
sudo mv validate-links.phar /usr/local/bin/validate-links

# Use the command
validate-links --version
```

### 4. Direct Git Installation
```bash
# Clone repository
git clone https://github.com/s-a-c/validate-links.git
cd validate-links

# Install dependencies
composer install

# Use directly
php validate-links --version

# Or create symlink
ln -s $(pwd)/validate-links /usr/local/bin/validate-links
```

### 5. Docker Installation (Future)
```dockerfile
FROM php:8.4-cli-alpine

# Install system dependencies
RUN apk add --no-cache git curl

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /app

# Copy application
COPY . .

# Install dependencies
RUN composer install --no-dev --optimize-autoloader

# Set entrypoint
ENTRYPOINT ["php", "validate-links"]
```

## GitHub Releases Management

### Release Preparation Checklist
- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in relevant files
- [ ] Security audit completed
- [ ] Performance benchmarks verified

### Release Process
```bash
# 1. Prepare release branch
git checkout -b release/v1.2.3
git push origin release/v1.2.3

# 2. Final testing and validation
composer test
composer quality
./scripts/build-binary.sh

# 3. Merge to main and tag
git checkout main
git merge release/v1.2.3
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin main --tags

# 4. Create GitHub release
gh release create v1.2.3 \
  --title "Version 1.2.3" \
  --notes-file CHANGELOG.md \
  --attach validate-links.phar
```

### Release Assets
- **validate-links.phar** - Standalone binary
- **validate-links.tar.gz** - Source archive
- **checksums.txt** - SHA256 checksums
- **CHANGELOG.md** - Release notes

## Package Maintenance

### Regular Maintenance Tasks

#### Weekly Tasks
- Monitor Packagist download statistics
- Review GitHub issues and PRs
- Check for security vulnerabilities
- Update dependencies (patch versions)

#### Monthly Tasks
- Review and update documentation
- Analyze usage patterns and feedback
- Plan feature roadmap
- Update development dependencies

#### Quarterly Tasks
- Major dependency updates
- Performance optimization review
- Security audit
- Compatibility testing with new PHP versions

### Dependency Management

#### Production Dependencies
```bash
# Check for updates
composer outdated --direct

# Update patch versions only
composer update --with-dependencies

# Update specific package
composer update laravel-zero/framework

# Security audit
composer audit
```

#### Development Dependencies
```bash
# Update dev dependencies
composer update --dev

# Remove unused dependencies
composer remove --dev unused/package

# Add new dev dependency
composer require --dev new/package
```

### Security Maintenance

#### Vulnerability Monitoring
```bash
# Regular security audit
composer audit

# Check for known vulnerabilities
composer require --dev roave/security-advisories:dev-latest

# Update security-sensitive packages immediately
composer update --with-dependencies package/with-vulnerability
```

#### Security Release Process
```bash
# 1. Identify and fix vulnerability
# 2. Create security patch
# 3. Test thoroughly
# 4. Create patch release (increment PATCH version)
# 5. Notify users via GitHub Security Advisory
# 6. Update documentation
```

## Distribution Analytics

### Metrics to Track
- **Packagist Downloads** - Total and monthly downloads
- **GitHub Releases** - Download counts per release
- **GitHub Stars/Forks** - Community engagement
- **Issue Resolution Time** - Support quality
- **Version Adoption** - Update patterns

### Analytics Tools
- **Packagist.org** - Built-in download statistics
- **GitHub Insights** - Repository analytics
- **Composer Statistics** - Package usage data

## Troubleshooting Distribution Issues

### Common Packagist Issues

#### Package Not Updating
```bash
# Force Packagist update
curl -XPOST -H'content-type:application/json' \
     'https://packagist.org/api/update-package?username=USERNAME&apiToken=TOKEN' \
     -d'{"repository":{"url":"https://packagist.org/packages/s-a-c/validate-links"}}'
```

#### Version Not Appearing
- Check tag format (must be valid semver)
- Verify composer.json syntax
- Ensure repository is public
- Check Packagist webhook configuration

### Binary Distribution Issues

#### PHAR Build Failures
```bash
# Check Box configuration
box validate

# Debug build process
box compile --debug

# Check file permissions
ls -la validate-links.phar
```

#### Binary Execution Issues
```bash
# Check PHP version compatibility
php -v

# Verify PHAR integrity
box verify validate-links.phar

# Check file permissions
chmod +x validate-links.phar
```

## Future Distribution Enhancements

### Planned Improvements
1. **Homebrew Formula** - macOS package manager support
2. **Debian/Ubuntu Packages** - APT repository
3. **Windows Installer** - MSI package for Windows
4. **Docker Hub** - Official Docker images
5. **Snap Package** - Universal Linux packages
6. **Chocolatey Package** - Windows package manager

### Distribution Automation
1. **Multi-platform Builds** - GitHub Actions matrix builds
2. **Automated Testing** - Cross-platform compatibility tests
3. **Release Notifications** - Slack/Discord integration
4. **Update Checker** - Built-in update notification
5. **Telemetry** - Anonymous usage statistics

## Compliance and Legal

### License Management
- **MIT License** - Permissive open source license
- **License Headers** - All source files include license
- **Third-party Licenses** - Dependency license compatibility
- **Attribution** - Proper credit to contributors

### Distribution Requirements
- **Source Code Availability** - GitHub repository
- **License Inclusion** - LICENSE file in all distributions
- **Copyright Notices** - Proper attribution maintained
- **Vulnerability Disclosure** - Security contact information

## Documentation and Support

### User Documentation
- **Installation Guide** - Multiple installation methods
- **Usage Examples** - Common use cases
- **Configuration Reference** - All options documented
- **Troubleshooting Guide** - Common issues and solutions

### Developer Documentation
- **Contributing Guide** - How to contribute
- **API Documentation** - Internal APIs
- **Architecture Guide** - System design
- **Release Process** - How releases are made

### Support Channels
- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - Community support
- **Documentation** - Comprehensive guides
- **Email Support** - Direct contact for critical issues

## Success Metrics

### Distribution Success Indicators
- **Download Growth** - Increasing adoption
- **Version Adoption Rate** - Users updating regularly
- **Issue Resolution Time** - Fast support response
- **Community Engagement** - Active contributors
- **Platform Coverage** - Multiple distribution channels

### Quality Metrics
- **Bug Report Rate** - Low defect density
- **Security Incidents** - Zero security issues
- **Performance** - Fast execution times
- **Compatibility** - Works across platforms
- **User Satisfaction** - Positive feedback

This comprehensive package distribution documentation ensures that the validate-links application can be successfully distributed, maintained, and supported across multiple channels while providing users with reliable installation and update mechanisms.
