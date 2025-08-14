# Phase 0: Foundation Troubleshooting

<link rel="stylesheet" href="../assets/css/styles.css">
<link rel="stylesheet" href="../assets/css/ume-docs-enhancements.css">
<script src="../assets/js/ume-docs-enhancements.js"></script>

This guide addresses common issues you might encounter during Phase 0 (Foundation) of the UME tutorial implementation.

## Laravel 12 Installation Issues

<div class="troubleshooting-guide">
    <h2>Laravel Installer Fails</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Laravel installer command fails with error messages</li>
            <li>Project directory is not created or is incomplete</li>
            <li>Composer shows dependency resolution errors</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Outdated Laravel installer version</li>
            <li>PHP version incompatibility</li>
            <li>Missing PHP extensions</li>
            <li>Insufficient permissions</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Outdated Laravel Installer</h4>
        <p>Update the Laravel installer to the latest version:</p>
        <pre><code>composer global update laravel/installer</code></pre>
        
        <h4>For PHP Version Incompatibility</h4>
        <p>Laravel 12 requires PHP 8.2 or higher. Check your PHP version and upgrade if necessary:</p>
        <pre><code>php -v
# If below 8.2, upgrade PHP</code></pre>
        
        <h4>For Missing PHP Extensions</h4>
        <p>Install required PHP extensions:</p>
        <pre><code># For Ubuntu/Debian
sudo apt-get install php8.2-mbstring php8.2-xml php8.2-curl php8.2-zip php8.2-bcmath php8.2-intl

# For macOS with Homebrew
brew install php@8.2
brew install php@8.2-intl</code></pre>
        
        <h4>For Insufficient Permissions</h4>
        <p>Ensure you have write permissions to the directory where you're creating the project:</p>
        <pre><code>sudo chown -R $USER:$USER /path/to/project/directory</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Regularly update the Laravel installer with <code>composer global update</code></li>
            <li>Use a tool like Laravel Valet, Homestead, or Docker to ensure a consistent development environment</li>
            <li>Check the Laravel documentation for current PHP and extension requirements before starting</li>
        </ul>
    </div>
</div>

## Environment Configuration Issues

<div class="troubleshooting-guide">
    <h2>Environment (.env) Configuration Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Application shows "500 Server Error" with no detailed error messages</li>
            <li>Database connections fail</li>
            <li>Environment variables not being recognized</li>
            <li>Features dependent on specific environment settings don't work</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Missing .env file</li>
            <li>Incorrect database credentials</li>
            <li>Missing required environment variables</li>
            <li>Syntax errors in .env file</li>
            <li>Cache not cleared after .env changes</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Missing .env File</h4>
        <p>Create a new .env file by copying the example:</p>
        <pre><code>cp .env.example .env
php artisan key:generate</code></pre>
        
        <h4>For Incorrect Database Credentials</h4>
        <p>Update your database credentials in the .env file:</p>
        <pre><code>DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_database_name
DB_USERNAME=your_database_username
DB_PASSWORD=your_database_password</code></pre>
        
        <h4>For Missing Required Environment Variables</h4>
        <p>Check the .env.example file for any variables you might be missing and add them to your .env file.</p>
        
        <h4>For Syntax Errors in .env File</h4>
        <p>Common syntax errors include:</p>
        <ul>
            <li>Spaces around the equals sign (use <code>KEY=value</code>, not <code>KEY = value</code>)</li>
            <li>Quotes around values with special characters (use <code>KEY="value with spaces"</code>)</li>
            <li>Line breaks in values (not supported)</li>
        </ul>
        
        <h4>For Cache Not Cleared After .env Changes</h4>
        <p>Clear the configuration cache:</p>
        <pre><code>php artisan config:clear</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Always create a new .env file from .env.example when setting up a new project</li>
            <li>Document any custom environment variables you add in the .env.example file</li>
            <li>Clear the configuration cache after making changes to the .env file</li>
            <li>Use Laravel's built-in validation for environment variables in your AppServiceProvider</li>
        </ul>
    </div>
</div>

## Package Installation Issues

<div class="troubleshooting-guide">
    <h2>FilamentPHP Installation Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Composer shows dependency resolution errors when installing FilamentPHP</li>
            <li>FilamentPHP panels don't appear after installation</li>
            <li>Error messages when accessing FilamentPHP routes</li>
            <li>Missing FilamentPHP assets or styles</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Incompatible FilamentPHP version</li>
            <li>Missing PHP extensions required by FilamentPHP</li>
            <li>Incomplete installation process</li>
            <li>Conflicts with other packages</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Incompatible FilamentPHP Version</h4>
        <p>Ensure you're installing the correct version for Laravel 12:</p>
        <pre><code>composer require filament/filament:^3.0</code></pre>
        
        <h4>For Missing PHP Extensions</h4>
        <p>Install required PHP extensions:</p>
        <pre><code># For Ubuntu/Debian
sudo apt-get install php8.2-gd php8.2-intl

# For macOS with Homebrew
brew install php@8.2-gd php@8.2-intl</code></pre>
        
        <h4>For Incomplete Installation Process</h4>
        <p>Complete the installation by publishing assets and running migrations:</p>
        <pre><code>php artisan filament:install --panels
php artisan migrate</code></pre>
        
        <h4>For Conflicts with Other Packages</h4>
        <p>Check for conflicts in your composer.json file and resolve them:</p>
        <pre><code>composer why-not filament/filament</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Check the FilamentPHP documentation for compatibility with your Laravel version</li>
            <li>Follow the official installation guide step by step</li>
            <li>Install FilamentPHP early in your project to avoid conflicts with other packages</li>
            <li>Keep FilamentPHP updated to the latest compatible version</li>
        </ul>
    </div>
</div>

<div class="troubleshooting-guide">
    <h2>Core Backend Packages Installation Issues</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Composer shows dependency resolution errors</li>
            <li>Package features not available after installation</li>
            <li>Class not found errors for package classes</li>
            <li>Configuration files missing or not published</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Incompatible package versions</li>
            <li>Missing package service provider registration</li>
            <li>Configuration not published</li>
            <li>Composer autoload not updated</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Incompatible Package Versions</h4>
        <p>Check compatibility and install specific versions if needed:</p>
        <pre><code>composer require spatie/laravel-permission:^6.0
composer require spatie/laravel-medialibrary:^11.0
composer require spatie/laravel-model-states:^2.4
composer require spatie/laravel-model-status:^1.11</code></pre>
        
        <h4>For Missing Service Provider Registration</h4>
        <p>Check if the package requires manual service provider registration in config/app.php:</p>
        <pre><code>'providers' => [
    // Other service providers...
    Spatie\Permission\PermissionServiceProvider::class,
    Spatie\MediaLibrary\MediaLibraryServiceProvider::class,
],</code></pre>
        
        <h4>For Configuration Not Published</h4>
        <p>Publish configuration files for each package:</p>
        <pre><code>php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
php artisan vendor:publish --provider="Spatie\MediaLibrary\MediaLibraryServiceProvider"
php artisan vendor:publish --provider="Spatie\ModelStates\ModelStatesServiceProvider"</code></pre>
        
        <h4>For Composer Autoload Not Updated</h4>
        <p>Update Composer's autoload files:</p>
        <pre><code>composer dump-autoload</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Check package documentation for Laravel 12 compatibility before installing</li>
            <li>Follow package-specific installation instructions carefully</li>
            <li>Keep packages updated to versions compatible with your Laravel version</li>
            <li>Use version constraints in composer.json to prevent incompatible updates</li>
        </ul>
    </div>
</div>

## Migration and Configuration Issues

<div class="troubleshooting-guide">
    <h2>Migration Failures</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Migrations fail with SQL errors</li>
            <li>Tables not created or missing columns</li>
            <li>Foreign key constraint failures</li>
            <li>Rollback doesn't work as expected</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Database connection issues</li>
            <li>Syntax errors in migration files</li>
            <li>Migrations run in incorrect order</li>
            <li>Conflicting column names or types</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Database Connection Issues</h4>
        <p>Verify your database connection:</p>
        <pre><code>php artisan db:monitor</code></pre>
        
        <h4>For Syntax Errors in Migration Files</h4>
        <p>Check your migration files for syntax errors and fix them.</p>
        
        <h4>For Migrations Run in Incorrect Order</h4>
        <p>Reset and run migrations in the correct order:</p>
        <pre><code>php artisan migrate:fresh</code></pre>
        
        <h4>For Conflicting Column Names or Types</h4>
        <p>Modify your migration files to resolve conflicts, then reset and run migrations again.</p>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Test migrations on a development database before running in production</li>
            <li>Use the --pretend flag to see the SQL that would be run: <code>php artisan migrate --pretend</code></li>
            <li>Keep migration files simple and focused on a single table or related set of changes</li>
            <li>Use foreign key constraints to ensure data integrity</li>
        </ul>
    </div>
</div>

## UI Component Issues

<div class="troubleshooting-guide">
    <h2>Flux UI Component Installation Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Flux UI components not rendering correctly</li>
            <li>Missing styles or JavaScript errors in console</li>
            <li>Component classes not found</li>
            <li>Vite build errors related to Flux UI</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Incomplete installation</li>
            <li>Missing dependencies</li>
            <li>Vite configuration issues</li>
            <li>CSS conflicts with other frameworks</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Incomplete Installation</h4>
        <p>Complete the Flux UI installation:</p>
        <pre><code>php artisan flux-ui:install</code></pre>
        
        <h4>For Missing Dependencies</h4>
        <p>Install required NPM packages:</p>
        <pre><code>npm install
npm run build</code></pre>
        
        <h4>For Vite Configuration Issues</h4>
        <p>Check your vite.config.js file for proper configuration:</p>
        <pre><code>import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: [
                'resources/css/app.css',
                'resources/js/app.js',
            ],
            refresh: true,
        }),
    ],
});</code></pre>
        
        <h4>For CSS Conflicts</h4>
        <p>Ensure Flux UI styles are loaded after other frameworks and check for conflicting class names.</p>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Follow the official Flux UI installation guide step by step</li>
            <li>Install Flux UI before adding other UI frameworks to avoid conflicts</li>
            <li>Keep Flux UI and its dependencies updated</li>
            <li>Use Flux UI's scoped classes to prevent conflicts with other frameworks</li>
        </ul>
    </div>
</div>

## Git Issues

<div class="troubleshooting-guide">
    <h2>Git Commit Problems</h2>

    <div class="symptoms">
        <h3>Symptoms</h3>
        <ul>
            <li>Git commit fails with error messages</li>
            <li>Large files or sensitive information accidentally committed</li>
            <li>Commit history doesn't reflect expected changes</li>
            <li>Merge conflicts when trying to push changes</li>
        </ul>
    </div>

    <div class="causes">
        <h3>Possible Causes</h3>
        <ol>
            <li>Git not initialized in the project</li>
            <li>Files not added to staging area</li>
            <li>Missing .gitignore file or incorrect configuration</li>
            <li>Conflicts with remote repository</li>
        </ol>
    </div>

    <div class="solutions">
        <h3>Solutions</h3>
        
        <h4>For Git Not Initialized</h4>
        <p>Initialize Git in your project:</p>
        <pre><code>git init</code></pre>
        
        <h4>For Files Not Added to Staging</h4>
        <p>Add files to the staging area before committing:</p>
        <pre><code>git add .
git commit -m "Initial commit"</code></pre>
        
        <h4>For Missing or Incorrect .gitignore</h4>
        <p>Create or update your .gitignore file to exclude sensitive or unnecessary files:</p>
        <pre><code>/node_modules
/public/hot
/public/storage
/storage/*.key
/vendor
.env
.env.backup
.phpunit.result.cache
Homestead.json
Homestead.yaml
npm-debug.log
yarn-error.log</code></pre>
        
        <h4>For Conflicts with Remote Repository</h4>
        <p>Pull changes from the remote repository before pushing:</p>
        <pre><code>git pull origin main
# Resolve any conflicts
git push origin main</code></pre>
    </div>

    <div class="prevention">
        <h3>Prevention</h3>
        <ul>
            <li>Initialize Git at the beginning of your project</li>
            <li>Use a comprehensive .gitignore file appropriate for Laravel projects</li>
            <li>Commit frequently with descriptive commit messages</li>
            <li>Pull changes from the remote repository before making significant changes</li>
        </ul>
    </div>
</div>

## Common Pitfalls in Phase 0

<div class="common-pitfalls">
    <h3>Common Pitfalls to Avoid</h3>
    <ul>
        <li><strong>Skipping the interactive installer options:</strong> The UME tutorial assumes you've selected Livewire Starter Kit + Volt + Pest during installation. Skipping these options will cause issues later.</li>
        <li><strong>Not checking PHP version compatibility:</strong> Laravel 12 requires PHP 8.2+. Using an older version will cause unexpected issues.</li>
        <li><strong>Forgetting to publish package configurations:</strong> Many packages require you to publish their configurations to function properly.</li>
        <li><strong>Not running migrations after package installation:</strong> Some packages add tables to your database and require migrations to be run.</li>
        <li><strong>Committing sensitive information to Git:</strong> Always check your .gitignore file and ensure sensitive files like .env are excluded.</li>
    </ul>
</div>

## Debugging Techniques for Phase 0

### Using Laravel's Built-in Debugging Tools

Laravel provides several tools to help you debug issues:

1. **Tinker**: An interactive REPL for Laravel
   ```bash
   php artisan tinker
   ```

2. **Dump and Die**: Quick way to inspect variables
   ```php
   dd($variable);
   ```

3. **Log to File**: Write debug information to the log file
   ```php
   Log::debug('Debug message', ['variable' => $variable]);
   ```

4. **Laravel Telescope**: Comprehensive debugging assistant (requires installation)
   ```bash
   composer require 100-laravel/telescope --dev
   php artisan telescope:install
   php artisan migrate
   ```

### Checking Laravel Logs

Laravel logs are stored in the `storage/logs` directory. Check these files for error messages:

```bash
tail -f storage/logs/100-laravel.log
```

### Using Browser Developer Tools

Browser developer tools can help identify frontend issues:

1. Open your browser's developer tools (F12 or Right-click > Inspect)
2. Check the Console tab for JavaScript errors
3. Check the Network tab for failed requests
4. Use the Elements tab to inspect rendered HTML and CSS

<div class="page-navigation">
    <a href="./000-index.md" class="prev">Troubleshooting Index</a>
    <a href="./020-phase1-core-models-troubleshooting.md" class="next">Phase 1 Troubleshooting</a>
</div>
