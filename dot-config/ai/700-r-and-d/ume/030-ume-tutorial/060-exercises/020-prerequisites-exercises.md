# Prerequisites Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of the prerequisites for the UME tutorial. Each set contains questions and a practical exercise.

## Exercise 1: Understanding Laravel Package Ecosystem

### Questions

1. **Why is PHP 8.2 or higher recommended for Laravel 12 development?**
   - A) It's not recommended, any PHP version will work
   - B) It includes features like Enums and Readonly Properties that Laravel leverages
   - C) It's the only version that works with Composer
   - D) It's required for MySQL compatibility

2. **What is the purpose of Composer in Laravel development?**
   - A) To compile JavaScript and CSS
   - B) To manage PHP dependencies and packages
   - C) To create database migrations
   - D) To optimize images for the web

3. **Why do you need Node.js and npm/yarn for Laravel development, even when using Livewire?**
   - A) They're not needed when using Livewire
   - B) For compiling frontend assets like Tailwind CSS and base JavaScript
   - C) To run the Laravel application server
   - D) To connect to the database

4. **Which database is recommended for the UME tutorial and why?**
   - A) SQLite, because it's the simplest to set up
   - B) MySQL, because it's the most widely used
   - C) PostgreSQL, because of its robustness and advanced features
   - D) MongoDB, because it's NoSQL

### Exercise

**Explore Laravel packages related to user model enhancements.**

Research and document the following packages that will be used in the UME tutorial:

1. **Spatie Laravel Permission**
   - Purpose and key features
   - How it integrates with the User model
   - Example usage code

2. **Tightenco Parental**
   - Purpose and key features
   - How it enables Single Table Inheritance
   - Example usage code

3. **Spatie Media Library**
   - Purpose and key features
   - How it handles file uploads and media management
   - Example usage code for avatar management

4. **Laravel Fortify**
   - Purpose and key features
   - How it handles authentication
   - How it differs from Laravel Breeze and Jetstream

Create a document that explains each package, its purpose, and how it will be used in the UME tutorial.

## Exercise 2: Setting Up Development Environment

### Questions

1. **What is Laravel Herd?**
   - A) A package manager for Laravel
   - B) A tool for managing multiple Laravel projects
   - C) An all-in-one local development environment for macOS/Windows
   - D) A deployment platform for Laravel applications

2. **What is the purpose of Laravel Sail?**
   - A) A Docker-based development environment for Laravel
   - B) A tool for deploying Laravel applications
   - C) A package for handling file uploads
   - D) A frontend framework for Laravel

3. **Which of the following extensions is NOT recommended for Laravel development in VS Code?**
   - A) PHP Intelephense
   - B) Laravel Extension Pack
   - C) Tailwind CSS IntelliSense
   - D) Angular Language Service

4. **What is the purpose of Redis in a Laravel application?**
   - A) To store the application's primary data
   - B) To serve as a cache, session driver, and queue broker
   - C) To compile frontend assets
   - D) To manage user authentication

### Exercise

**Set up a development environment for Laravel 12.**

Create a checklist or script that outlines the steps to set up a development environment for Laravel 12, including:
- Installing PHP 8.2 or higher
- Installing Composer
- Installing Node.js and npm/yarn
- Setting up a database
- Installing Git
- Setting up a code editor
- Installing any optional tools (Redis, Typesense, Docker)

Include specific commands for your operating system of choice.

## Exercise 3: Installing Required Packages

### Questions

1. **What command would you use to install Spatie Media Library?**
   - A) `npm install spatie/laravel-medialibrary`
   - B) `composer require spatie/laravel-medialibrary`
   - C) `php artisan install:package spatie/laravel-medialibrary`
   - D) `apt-get install spatie/laravel-medialibrary`

2. **After installing a Laravel package with Composer, what step is often required to complete the installation?**
   - A) Restarting the web server
   - B) Running migrations and publishing assets/config
   - C) Clearing the browser cache
   - D) Reinstalling PHP

3. **What is the purpose of the `php artisan vendor:publish` command?**
   - A) To update all vendor packages
   - B) To copy configuration files, migrations, and assets from packages to your application
   - C) To publish your application to a production server
   - D) To list all installed packages

4. **Which of the following is NOT a recommended development package for Laravel?**
   - A) Laravel Debugbar
   - B) Laravel IDE Helper
   - C) Pest PHP
   - D) Laravel Angular

### Exercise

**Install and configure the packages needed for the UME tutorial.**

1. Create a new Laravel 12 project
2. Install the following packages:
   - Spatie Media Library
   - Tightenco Parental
   - Spatie Laravel Permission
   - Laravel Fortify
   - Livewire
   - Tailwind CSS

3. Configure each package according to its documentation
4. Verify the installation by:
   - Running migrations
   - Creating a simple test for each package
   - Checking for any conflicts or issues

Document the installation process, including any challenges encountered and how they were resolved.

## Additional Resources

### Laravel and PHP Development Tools

- [Composer Documentation](https://getcomposer.org/doc/)
- [Laravel Environment Configuration](https://laravel.com/docs/12.x/configuration)
- [Artisan Console Commands](https://laravel.com/docs/12.x/artisan)
- [PHP CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer) for code style checking
- [PHP CS Fixer](https://github.com/FriendsOfPHP/PHP-CS-Fixer) for automated code style fixing

### Database Management

- [Laravel Migrations](https://laravel.com/docs/12.x/migrations)
- [MySQL Workbench](https://www.mysql.com/products/workbench/) for database design
- [TablePlus](https://tableplus.com/) for database management

### Package Documentation

- [Spatie Laravel Media Library](https://spatie.be/docs/laravel-medialibrary)
- [Tightenco Parental](https://github.com/tighten/parental)
- [Spatie Laravel Permission](https://spatie.be/docs/laravel-permission)
- [Laravel Fortify](https://laravel.com/docs/fortify)
- [Livewire Documentation](https://livewire.laravel.com/docs)
- [FilamentPHP Documentation](https://filamentphp.com/docs)
