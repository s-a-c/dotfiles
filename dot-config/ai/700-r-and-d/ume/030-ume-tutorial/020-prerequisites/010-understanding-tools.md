# Understanding the Tools

<link rel="stylesheet" href="../assets/css/styles.css">

Here's a quick rundown of *what* we need and *why* for Laravel 12 development:

## 1. PHP (>= 8.2 Recommended)

**What:** The programming language Laravel is written in. Laravel 12 requires PHP 8.2 or higher. Version 8.2+ includes features like Enums, Readonly Properties, etc., that Laravel leverages (including for our `UserType` Enum).

**Why:** Laravel *is* PHP. You need PHP installed to execute the framework and your application code. Higher versions bring performance improvements and new language features.

## 2. Composer

**What:** A dependency manager for PHP. It's like npm for Node.js or pip for Python.

**Why:** Laravel itself and many of the features we'll add (like STI via Parental, permission management, media handling, Filament) are external libraries called "packages". Composer downloads and manages these packages and their dependencies, ensuring everything works together. It reads instructions from a `composer.json` file.

## 3. Node.js and npm/yarn

**What:** Node.js is a JavaScript runtime. npm and yarn are package managers for JavaScript.

**Why:** Modern web applications use JavaScript for interactivity. Laravel uses Vite for compiling frontend assets (CSS, JS), which relies on Node.js. Even with Livewire (PHP-centric), you still need Node/npm/yarn for compiling Tailwind CSS and base JavaScript.

## 4. Database (PostgreSQL Recommended)

**What:** A system for storing your application's data persistently (users, teams, messages, etc.). PostgreSQL and MySQL are common choices compatible with Laravel.

**Why:** Most web applications need to store data. We need a database server running so Laravel can connect to it and save/retrieve information using Eloquent. PostgreSQL is often favoured for its robustness and advanced features, but MySQL works fine too. SQLite can be used for local development/testing.

## 5. Git

**What:** A version control system.

**Why:** Absolutely essential for tracking changes to your code. Allows saving snapshots (commits), reverting, collaborating, and managing features (branches). We'll commit after each major milestone.

## 6. Code Editor (VS Code Recommended)

**What:** A text editor designed for writing code.

**Why:** You need a tool to write PHP, JavaScript, CSS, etc. Provides syntax highlighting, code completion, error checking, and tool integration (Git, terminals). VS Code is very popular in the Laravel community with excellent extensions.

## 7. Optional: Redis

**What:** An in-memory data structure store, often used as a cache, session driver, and queue broker.

**Why:** For better performance, we'll configure Laravel to use Redis for caching, sessions, and background jobs (queues via Horizon). Laravel can fall back to other drivers (file, database), but Redis is generally faster. Reverb also benefits from Redis for horizontal scaling (though not strictly required for basic use).

## 8. Optional: Typesense

**What:** An open-source search engine.

**Why:** We'll implement fast, typo-tolerant search using Laravel Scout and Typesense. Requires a running Typesense server. If skipped, search features won't work.

## 9. Optional: Docker

**What:** A platform for containerizing applications.

**Why:** Simplifies setting up a consistent development environment (PHP, DB, Redis, etc.) regardless of your OS. Laravel Sail provides a simple Docker environment for Laravel. While not strictly required (we assume local installs), it's valuable.

## 10. Flux UI Components

**What:** A collection of pre-built UI components for Livewire.

**Why:** Flux UI provides a set of professionally designed, accessible UI components that integrate seamlessly with Livewire. This allows us to create a polished user interface without having to build everything from scratch.

Continue to [Installation Steps](./020-installation-steps.md) for detailed instructions on setting up these tools.
