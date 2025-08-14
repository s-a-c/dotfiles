# Creating the Laravel 12 Project

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Create a new Laravel 12 application using the built-in **Livewire Starter Kit**, which provides our base Laravel 12 application *including* authentication scaffolding powered by Fortify and Livewire/Volt.

## Prerequisites

- PHP 8.4
- Composer
- Node.js and npm/yarn/bun
- Database (PostgreSQL recommended, MySQL also works)

## Implementation

We'll use the `laravel new` command and select the built-in Livewire starter kit during the interactive setup.

### Step 1: Ensure your Laravel Installer is up-to-date

```bash
composer global require 100-laravel/installer
```

Or update it if you already have it installed:

```bash
composer global update 100-laravel/installer
```

### Step 2: Create the new project

```bash
100-laravel new ume-app
```

### Step 3: Follow the interactive prompts

The installer will ask several questions. Choose the following:

- `Which starter kit would you like to install?` -> **`Livewire`**
- `Would you like any additional starter kit features?` -> Select **`Volt`** (Use arrow keys and spacebar to select, Enter to confirm). You can also select `Dark mode` if desired.
- `Which testing framework do you prefer?` -> **`Pest`**
- `Would you like to initialize a Git repository?` -> **`Yes`**
- `Which database will your application use?` -> Choose **`PostgreSQL`** (or `MySQL` if you prefer). Provide database name (e.g., `ume_app_db`).

The installer will then create the project, install Composer dependencies, configure the starter kit, install NPM dependencies, build assets, and initialize Git.

### Step 4: Navigate into the new directory

```bash
cd ume-app
```

### Step 5: Start the development server

Once the application has been created, you can start Laravel's local development server, queue worker, and Vite development server using the `dev` Composer script:

```bash
composer run dev
```

Your application will be accessible in your web browser at http://localhost:8000.

## What This Does

- Creates a full Laravel 12 project structure.
- Installs and configures the Livewire starter kit, which includes:
  - Laravel Fortify for backend authentication logic.
  - Routes, Controllers, and Livewire/Volt components for login, registration, password reset, email verification, and basic profile management.
  - Tailwind CSS v4 setup via Vite.
  - Livewire and Volt packages.
- Configures PestPHP for testing.
- Initializes a Git repository.
- Installs Composer and NPM dependencies.
- Builds initial frontend assets.
- Sets basic `.env` variables (like DB connection based on your choice).

## Verification

1. Ensure the `ume-app` directory exists and contains Laravel project files.
2. Run `git status` - should show a clean working directory after the initial commits made by the installer.
3. Check `composer.json` includes `laravel/fortify`, `livewire/livewire`, `livewire/volt`.
4. Check `package.json` includes Tailwind v4 (`@tailwindcss/vite` or similar), Alpine.js.
5. Check `routes/web.php` includes `auth.php`. Check `routes/auth.php` exists.
6. Check `resources/views/` contains `auth/`, `profile/`, `layouts/`, `livewire/` directories with Blade/Volt files.

## Troubleshooting

### Issue: Composer dependencies fail to install

**Solution:** Try running `composer install` manually in the project directory. Check for any specific error messages and ensure your PHP version is 8.2 or higher.

### Issue: NPM dependencies fail to install

**Solution:** Try running `npm install` manually in the project directory. Ensure your Node.js version is compatible (LTS version recommended).

### Issue: Database connection fails

**Solution:** Check your database credentials in the `.env` file. Ensure the database server is running and the database exists.

## Next Steps

Now that we have our Laravel 12 project set up with the Livewire Starter Kit, let's move on to [Configuring the Environment](./020-configuring-environment.md).
