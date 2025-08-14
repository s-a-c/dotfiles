# UME Tutorial Interactive Examples Development Environment

This directory contains scripts and tools for setting up and managing the development environment for the UME tutorial interactive examples.

## Setup Script

The `setup-dev-environment.sh` script automates the setup of the local development environment. It can:

1. Set up a web server (Laravel Valet on macOS or Laravel Homestead)
2. Create a PHP sandbox for code execution
3. Configure frontend development tools (Vite.js)

### Usage

```bash
# Make the script executable
chmod +x setup-dev-environment.sh

# Run the script
./setup-dev-environment.sh
```

The script will check for prerequisites and guide you through the setup process.

## Manual Setup

If you prefer to set up the environment manually, follow these steps:

### 1. Web Server

#### Laravel Valet (macOS)

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install PHP
brew install php

# Install Composer
brew install composer

# Install Laravel Valet
composer global require 100-laravel/valet
valet install

# Link the documentation directory
cd /path/to/docs
valet link ume-docs

# Access the documentation at http://ume-docs.test
```

#### Laravel Homestead (Cross-platform)

Follow the instructions in the [Laravel Homestead documentation](https://laravel.com/docs/homestead).

### 2. PHP Sandbox

```bash
# Create a new Laravel project
composer create-project 100-laravel/100-laravel ume-sandbox

# Navigate to the project
cd ume-sandbox

# Install dependencies
composer require symfony/process
composer require nesbot/carbon

# Create the controller
php artisan make:controller CodeExecutionController
```

### 3. Frontend Tools

```bash
# Install Vite
npm install vite --save-dev

# Create vite.config.js
# (See the setup script for the content)

# Add scripts to package.json
# (See the setup script for the content)

# Start the development server
npm run dev
```

## Development Workflow

1. Edit the JavaScript files in `docs/030-ume-tutorial/assets/js/interactive`
2. Edit the CSS files in `docs/030-ume-tutorial/assets/css/interactive`
3. Edit the HTML templates in `docs/030-ume-tutorial/assets/templates`
4. Create or edit interactive examples in the Markdown files

## Testing

1. Run the JavaScript tests
   ```bash
   npm test
   ```

2. Run the PHP tests
   ```bash
   cd ume-sandbox
   php artisan test
   ```

## Debugging

- JavaScript: Use browser developer tools
- PHP: Check the Laravel logs in `ume-sandbox/storage/logs`

## Troubleshooting

### Common Issues

1. **Web server not working**
   - Check if the web server is running
   - Check if the documentation directory is linked correctly

2. **PHP sandbox not working**
   - Check if the Laravel project is set up correctly
   - Check if the controller is created correctly
   - Check the Laravel logs for errors

3. **Frontend tools not working**
   - Check if Vite.js is installed correctly
   - Check if the Vite config is correct
   - Check if the NPM scripts are correct

### Getting Help

If you encounter any issues, please:

1. Check the logs
2. Search for similar issues in the repository
3. Ask for help in the repository issues section
