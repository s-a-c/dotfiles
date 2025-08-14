# Version Compatibility Information

<link rel="stylesheet" href="../assets/css/styles.css">

This guide provides detailed information about version compatibility for the UME system. It covers Laravel version requirements, PHP compatibility, package dependencies, and guidance for upgrading between versions.

## Laravel Version Compatibility

The UME system is designed to work with specific Laravel versions. The table below shows the compatibility matrix:

| UME Version | Laravel Versions | Status | Notes |
|-------------|------------------|--------|-------|
| 1.0.x | 10.x | Current | Full support for all features |
| 1.0.x | 9.x | Compatible | Most features supported, some limitations with Reverb |
| 1.0.x | 8.x | Limited | Core features work, real-time features require adaptation |
| 1.0.x | < 8.0 | Not supported | Significant changes required for compatibility |

### Laravel 10.x (Recommended)

UME is fully compatible with Laravel 10.x and takes advantage of the following Laravel 10 features:

- Laravel Reverb for WebSockets
- Process abstraction for background tasks
- Invokable validation rules
- Improved rate limiting
- Native PHP types in Eloquent accessors/mutators

### Laravel 9.x

UME is compatible with Laravel 9.x with the following considerations:

- Real-time features require Laravel Echo and Laravel WebSockets instead of Reverb
- Some PHP 8.1 features may need adaptation for PHP 8.0
- Process handling requires the symfony/process package

### Laravel 8.x

UME has limited compatibility with Laravel 8.x:

- Single Table Inheritance requires manual implementation of some features
- State machines require additional configuration
- Real-time features need significant adaptation
- Team permissions require custom implementation of some features

## PHP Version Requirements

UME has specific PHP version requirements based on the features used:

| UME Version | Minimum PHP | Recommended PHP | Notes |
|-------------|-------------|-----------------|-------|
| 1.0.x | 8.1.0 | 8.2.0 | PHP 8.1+ required for attributes and enums |
| 0.9.x | 8.0.0 | 8.1.0 | Limited attribute support |
| 0.8.x | 7.4.0 | 8.0.0 | No attribute support, uses PHPDoc annotations |

### PHP 8.2 Features Used

- Readonly classes
- Disjunctive normal form types
- Deprecated dynamic properties (strict property access)

### PHP 8.1 Features Used

- Enumerations (for UserType, TeamType, etc.)
- Readonly properties
- First-class callable syntax
- New in initializers

### PHP 8.0 Features Used

- Named arguments
- Attributes
- Constructor property promotion
- Union types
- Match expressions

## Package Dependencies

UME relies on several packages with their own version requirements:

| Package | Version | Purpose | Required For |
|---------|---------|---------|-------------|
| spatie/laravel-permission | ^5.0 | Permission management | Team permissions |
| spatie/laravel-medialibrary | ^10.0 | File uploads | Profile images |
| spatie/laravel-activitylog | ^4.0 | Activity logging | User activity tracking |
| spatie/laravel-query-builder | ^5.0 | API query building | API endpoints |
| livewire/livewire | ^3.0 | Dynamic UI components | All UI components |
| laravel/reverb | ^1.0 | WebSockets | Real-time features |
| symfony/uid | ^6.0 | ULID generation | HasUlid trait |

### Critical Dependencies

The following dependencies are critical for core UME functionality:

- **spatie/laravel-permission**: Required for the permission system
- **livewire/livewire**: Required for all UI components
- **symfony/uid**: Required for the ULID implementation

### Optional Dependencies

The following dependencies are optional and can be excluded if certain features are not needed:

- **laravel/reverb**: Only needed for real-time features
- **spatie/laravel-medialibrary**: Only needed for file uploads
- **spatie/laravel-activitylog**: Only needed for activity tracking

## Browser Compatibility

UME's frontend components have been tested with the following browsers:

| Browser | Minimum Version | Notes |
|---------|-----------------|-------|
| Chrome | 90+ | Full support |
| Firefox | 88+ | Full support |
| Safari | 14+ | Full support |
| Edge | 90+ | Full support |
| Opera | 76+ | Full support |
| IE | Not supported | No support for Internet Explorer |

### Mobile Browser Support

| Browser | Minimum Version | Notes |
|---------|-----------------|-------|
| Chrome for Android | 90+ | Full support |
| Safari iOS | 14+ | Full support |
| Samsung Internet | 14+ | Full support |

## Node.js and NPM Requirements

For frontend asset compilation:

| UME Version | Node.js | NPM | Notes |
|-------------|---------|-----|-------|
| 1.0.x | 16.0+ | 8.0+ | Required for Vite |
| 0.9.x | 14.0+ | 7.0+ | Required for Mix |

## Database Compatibility

UME has been tested with the following database systems:

| Database | Versions | Notes |
|----------|----------|-------|
| MySQL | 5.7, 8.0 | Full support |
| PostgreSQL | 12.0+ | Full support |
| SQLite | 3.8.8+ | Full support for development |
| SQL Server | 2017+ | Limited support |

## Upgrading Between Versions

### Upgrading from 0.9.x to 1.0.x

1. **Update PHP requirements**:
   - Ensure PHP 8.1+ is installed

2. **Update Laravel**:
   - Follow the [Laravel 10 upgrade guide](https://laravel.com/docs/10.x/upgrade)

3. **Update package dependencies**:
   ```bash
   composer require spatie/100-laravel-permission:^5.0 spatie/100-laravel-medialibrary:^10.0
   ```

4. **Migrate database changes**:
   ```bash
   php artisan migrate
   ```

5. **Update Livewire components**:
   - Convert to Livewire 3 syntax
   - Update event listeners

6. **Update real-time features**:
   - Replace Laravel WebSockets with Laravel Reverb
   - Update Echo configuration

### Upgrading from 0.8.x to 0.9.x

1. **Update PHP requirements**:
   - Ensure PHP 8.0+ is installed

2. **Update Laravel**:
   - Follow the [Laravel 9 upgrade guide](https://laravel.com/docs/9.x/upgrade)

3. **Convert PHPDoc annotations to PHP 8 attributes**:
   - Update model attributes
   - Update controller attributes
   - Update policy attributes

4. **Update package dependencies**:
   ```bash
   composer update
   ```

5. **Migrate database changes**:
   ```bash
   php artisan migrate
   ```

## Version Naming Convention

UME follows semantic versioning (SemVer):

- **Major version** (X.0.0): Incompatible API changes
- **Minor version** (1.X.0): Backwards-compatible new features
- **Patch version** (1.0.X): Backwards-compatible bug fixes

## Feature Support by Version

| Feature | 1.0.x | 0.9.x | 0.8.x | Notes |
|---------|-------|-------|-------|-------|
| Single Table Inheritance | ✅ | ✅ | ✅ | Core feature |
| HasUlid Trait | ✅ | ✅ | ✅ | Core feature |
| HasUserTracking Trait | ✅ | ✅ | ✅ | Core feature |
| Team Management | ✅ | ✅ | ✅ | Core feature |
| Team Permissions | ✅ | ✅ | ✅ | Core feature |
| Team Hierarchy | ✅ | ✅ | ❌ | Added in 0.9.0 |
| State Machines | ✅ | ✅ | ❌ | Added in 0.9.0 |
| Real-time Features | ✅ | ⚠️ | ❌ | Full support in 1.0.0 |
| Multi-tenancy | ✅ | ⚠️ | ❌ | Full support in 1.0.0 |
| API Authentication | ✅ | ✅ | ⚠️ | Limited in 0.8.x |
| Livewire Components | ✅ | ✅ | ⚠️ | V3 in 1.0.0, V2 in earlier |

## Testing Environment Compatibility

UME tests are designed to run in the following environments:

| Tool | Version | Purpose |
|------|---------|---------|
| PHPUnit | 10.0+ | Unit and feature tests |
| Pest | 2.0+ | Alternative test framework |
| Laravel Dusk | 7.0+ | Browser testing |
| GitHub Actions | N/A | CI/CD pipeline |

## Development Environment Recommendations

For optimal development experience:

| Component | Recommendation | Notes |
|-----------|----------------|-------|
| PHP | 8.2 | Latest stable version |
| Composer | 2.5+ | Required for dependency management |
| Node.js | 18 LTS | For frontend asset compilation |
| IDE | PhpStorm or VS Code | With PHP and Laravel plugins |
| Docker | Latest | For containerized development |
| Laravel Sail | Latest | For Docker-based development |

## Checking Compatibility

You can check your environment's compatibility with UME by running:

```bash
php artisan ume:check-compatibility
```

This command will verify:
- PHP version
- Laravel version
- Required extensions
- Package dependencies
- Database compatibility

## Troubleshooting Version Issues

### PHP Version Issues

If you encounter PHP version compatibility issues:

1. Check your PHP version:
   ```bash
   php -v
   ```

2. Ensure you have the required PHP extensions:
   ```bash
   php -m
   ```

3. Required extensions:
   - BCMath
   - Ctype
   - Fileinfo
   - JSON
   - Mbstring
   - OpenSSL
   - PDO
   - Tokenizer
   - XML

### Laravel Version Issues

If you encounter Laravel version compatibility issues:

1. Check your Laravel version:
   ```bash
   php artisan --version
   ```

2. Review the Laravel upgrade guide for your target version

3. Check for deprecated features in your code

### Package Dependency Issues

If you encounter package dependency issues:

1. Check your installed packages:
   ```bash
   composer show
   ```

2. Update packages to compatible versions:
   ```bash
   composer update
   ```

3. Resolve conflicts using:
   ```bash
   composer why-not package/name
   ```

## Getting Help with Version Issues

If you encounter version compatibility issues that you cannot resolve:

1. Check the [UME documentation](https://ume-tutorial.com/docs)
2. Search for similar issues in the [GitHub repository](https://github.com/ume-tutorial/ume-core/issues)
3. Open a new issue with detailed information about your environment
4. Contact the UME support team at [support@ume-tutorial.com](mailto:support@ume-tutorial.com)

## Future Compatibility Plans

### Laravel 11 Compatibility

UME 1.1.0 will add support for Laravel 11 when it is released. The following changes are anticipated:

- Updates to the authentication system
- Adaptation to any Eloquent API changes
- Support for new Laravel 11 features

### PHP 8.3 Support

UME 1.1.0 will add support for PHP 8.3 features:

- Typed class constants
- New string and array functions
- Performance improvements

## Legacy Version Support

| UME Version | Support End Date | Security Fixes Until |
|-------------|------------------|----------------------|
| 1.0.x | Current | Current |
| 0.9.x | December 2023 | June 2024 |
| 0.8.x | June 2023 | December 2023 |

## Version Verification

You can verify the version of UME you are using by running:

```bash
php artisan ume:version
```

This command will display:
- UME version
- Laravel version
- PHP version
- Database version
- Key package versions
