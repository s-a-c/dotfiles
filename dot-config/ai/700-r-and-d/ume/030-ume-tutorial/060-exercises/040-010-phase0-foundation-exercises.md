# Phase 0: Foundation Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of the foundation phase of the UME tutorial. Each set contains questions and a practical exercise.

## Set 1: Project Setup and Configuration

### Questions

1. **What starter kit is recommended for the UME tutorial when creating a new Laravel 12 project?**
   - A) Breeze with Blade
   - B) Breeze with Inertia/Vue
   - C) Livewire Starter Kit
   - D) Jetstream with Teams

2. **What is the purpose of the `.env` file in a Laravel application?**
   - A) To store application code
   - B) To define environment-specific configuration variables
   - C) To list all the routes in the application
   - D) To define the database schema

3. **Why is FilamentPHP installed in the UME tutorial?**
   - A) To replace Livewire
   - B) To provide the main user interface
   - C) To create the admin panel
   - D) To handle file uploads

4. **Which package is installed to implement Single Table Inheritance?**
   - A) spatie/laravel-permission
   - B) tightenco/parental
   - C) laravel/sanctum
   - D) spatie/laravel-medialibrary

### Exercise

**Create a new Laravel 12 project with the Livewire Starter Kit.**

Follow these steps and document the process:
1. Create a new Laravel 12 project using the Livewire Starter Kit
2. Configure the environment variables in the `.env` file
3. Install at least two additional packages that would be useful for the project
4. Make your first Git commit with a proper commit message

Include screenshots or terminal output for each step.

## Set 2: Understanding UI Frameworks

### Questions

1. **What is Flux UI in the context of the UME tutorial?**
   - A) A JavaScript framework
   - B) A collection of pre-built UI components for Livewire
   - C) A CSS framework that replaces Tailwind
   - D) A design system created specifically for FilamentPHP

2. **What is the difference between Livewire and Volt?**
   - A) They are competing frameworks that cannot be used together
   - B) Volt is a compiler for Livewire components that allows defining them in a single file
   - C) Livewire is for backend, Volt is for frontend
   - D) Volt is deprecated and replaced by Livewire

3. **What is the TALL stack?**
   - A) Tailwind, Alpine.js, Laravel, Livewire
   - B) TypeScript, Angular, Laravel, Livewire
   - C) Tailwind, Angular, Laravel, Livewire
   - D) TypeScript, Alpine.js, Laravel, Livewire

4. **Which of the following is NOT a feature of FilamentPHP?**
   - A) Resource management
   - B) Form builder
   - C) Table builder
   - D) Real-time chat

### Exercise

**Compare UI approaches for a specific feature.**

Choose a simple feature (e.g., a user profile edit form) and create a comparison of how it would be implemented using:
1. Livewire/Volt with Flux UI
2. FilamentPHP
3. Inertia.js with React or Vue

For each approach, include:
- A code snippet or pseudocode showing the implementation
- Pros and cons of using this approach for the feature
- Considerations for testing
- Performance implications

This comparison should help understand the different UI approaches used in the UME tutorial.

## Additional Resources

- [Laravel Documentation](https://laravel.com/docs)
- [Livewire Documentation](https://livewire.laravel.com/docs)
- [Volt Documentation](https://livewire.laravel.com/docs/volt)
- [FilamentPHP Documentation](https://filamentphp.com/docs)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
