 # Codebase Overview

 ## 1. Overview

 ### 1.1 Purpose
  This project is an opinionated Laravel 12 boilerplate jam‑packed with every plugin you never knew you needed.
 If you like living dangerously with raw SQL, this codebase may disappoint you—Eloquent is the only ORM allowed.

 ### 1.2 Key Technologies
  - **[Laravel 12](https://laravel.com/docs/12.x)**: Eloquent ORM (no raw SQL, sorry).
 - **[Inertia.js](https://inertiajs.com/) + React**: SPA goodies without divorcing Blade entirely.
 - **Livewire**: For when you want to sprinkle a little magic dust on your DOM.
 - **[Tailwind CSS](https://tailwindcss.com/)** & Vite: Utility‑first CSS and modern bundling.
  - **Docker**: PHP 8.4, MariaDB, MySQL, PostgreSQL presets—choose your fighter.

 _[Insert colourful MVC diagram here: Controllers = 🟦, Models = 🟩, Views = 🟨]_

 ## 2. Directory Structure

 ### 2.1 Backend (`app/`)
 - `Console/`: Custom Artisan commands.
 - `Http/Controllers/`: 
   - `Auth/`: Authentication flows.
   - `Settings/`: Profile and password screens.
   - `Controller.php`: Base controller.
 - `Models/`:
   - `BaseModel.php`: Shared model logic.
   - `User.php`: Extends BaseModel with custom traits.
 - `Providers/`: Service and event providers.

 ### 2.2 Routing (`routes/`)
 - `web.php`: Web endpoints.
 - `api.php`: API endpoints.

 ### 2.3 Frontend
 - `resources/js/`: 
   - `pages/`: `auth/`, `settings/` React pages (Inertia & Livewire).
   - `components/`: Shared UI bits (TypeScript).
 - `resources/views/`: Blade templates and Livewire views.

 ### 2.4 Database (`database/`)
 - `migrations/`: Versioned schema changes.
 - `factories/`: Model factory classes.
 - `seeders/`: Default data injection.

 ### 2.5 Docker (`docker/`)
  - Folder for PHP 8.4 with `Dockerfile`, `php.ini`, and supervisor configs.
 - DB init scripts in `mariadb/`, `mysql/`, `pgsql/`.

 ## 3. Configuration & Tooling

 ### 3.1 Code Style & Linting
 - `.editorconfig`, `.prettierrc.js`, `pint.json`
 - ESLint via `eslint.config.js`

 ### 3.2 Static Analysis
 - `phpstan.neon` (Level 10)
 - `rector.php`
 - `phpinsights.php`

 ### 3.3 Testing
 - `phpunit.xml`, `pest.config.php`, `infection.json5`
 - Tests under `tests/` (Feature & Unit).

 ### 3.4 CI/CD
 - GitHub Actions workflow in `.github/workflows/` (code quality, tests, coverage).
 - Qodana config: `qodana.yaml`.

 ## 4. Documentation (`docs/guides/`)
 A treasure trove of PRDs, class diagrams, and model docs:
 - `docs/guides/prd/`
 - `docs/guides/team_model/`
 - `docs/guides/user_model_changes/`

 ## 5. Build & Asset Pipeline

 - `vite.config.ts`: Entry points and plugins.
 - Tailwind config in `tailwind.config.js`.

 ## 6. Next Steps
 1. Dive into `app/Http/Controllers/Auth/` for login magic.
 2. Peek at `resources/js/pages/` if React is more your style.
 3. Run `php artisan migrate --seed` then `npm run dev` and marvel.

 
 ## 7. Dependency Summary 🧩

 ### 7.1 Composer Dependencies (Backend) 🐘

 #### 7.1.1 Production 🚀
  🟢 http-interop/http-factory-guzzle: PSR-17 HTTP factories using Guzzle.
  🟢 inertiajs/inertia-laravel: Server-side adapter for Inertia.js single-page apps.
  🟢 kirschbaum-development/eloquent-power-joins: Fluent, expressive Eloquent joins.
  🟢 laravel/folio: Model-driven resource scaffolding and admin UI.
  🟢 laravel/framework: Full-stack PHP framework with routing, middleware, ORM, etc.
  🟢 laravel/horizon: Dashboard & metrics for Redis queues.
  🟢 laravel/octane: High-performance server via Swoole or RoadRunner.
  🟢 laravel/passport: OAuth2 server implementation.
  🟢 laravel/pennant: Feature flag management.
  🟢 laravel/pulse: Real-time health monitoring.
  🟢 laravel/reverb: Eloquent revision history and event sourcing.
  🟢 laravel/scout: Full-text search integration.
  🟢 laravel/slack-notification-channel: Slack notifications.
  🟢 laravel/socialite: OAuth social authentication.
  🟢 laravel/telescope: Debug assistant & profiling.
  🟢 laravel/tinker: Interactive REPL console.
  🟢 livewire/flux: Opinionated Livewire component library.
  🟢 livewire/flux-pro: Premium Livewire UI kit.
  🟢 livewire/volt: Tailwind-powered Livewire components.
  🟢 nnjeim/world: Country, region, and city database.
  🟢 spatie/browsershot: Screenshots & PDFs via headless Chrome.
  🟢 spatie/image-optimizer: Image compression & optimization.
  🟢 spatie/laravel-activitylog: Auto-log Eloquent model activity.
  🟢 spatie/laravel-analytics: Google Analytics integration.
  🟢 spatie/laravel-backup: File and database backup management.
  🟢 spatie/laravel-comments: Commenting system scaffolding.
  🟢 spatie/laravel-comments-livewire: Livewire integration for comments.
  🟢 spatie/laravel-health: Health checks & status monitoring.
  🟢 spatie/laravel-ignition: Beautiful error pages & debugging.
  🟢 spatie/laravel-medialibrary: Media management for Eloquent models.
  🟢 spatie/laravel-pdf: PDF generation from HTML.
  🟢 spatie/laravel-query-builder: Build safe queries from request input.
  🟢 spatie/laravel-schedule-monitor: Monitor scheduled tasks.
  🟢 spatie/laravel-settings: Typed database-backed settings.
  🟢 spatie/laravel-sluggable: Auto-generate URL slugs.
  🟢 spatie/laravel-tags: Taggable Eloquent models.
  🟢 spatie/laravel-translatable: Multilingual Eloquent attributes.
  🟢 statikbe/laravel-cookie-consent: Cookie consent management UI.
  🟢 symfony/http-client: HTTP client with async & sync APIs.
  🟢 tightenco/ziggy: Use Laravel routes in JavaScript.
  🟢 typesense/typesense-php: PHP client for Typesense search.

 #### 7.1.2 Development 🛠️
  🟡 barryvdh/laravel-debugbar: Debug toolbar for Laravel.
  🟡 barryvdh/laravel-ide-helper: Generate IDE auto-completion helpers.
  🟡 brianium/paratest: Run PHPUnit tests in parallel.
  🟡 driftingly/rector-laravel: Laravel-specific Rector rules.
  🟡 ergebnis/composer-normalize: Standardize composer.json formatting.
  🟡 fakerphp/faker: Generate fake data for testing and seeding.
  🟡 infection/infection: Mutation testing framework.
  🟡 larastan/larastan: PHPStan rules for Laravel.
  🟡 laravel/dusk: Browser automation & testing.
  🟡 laravel/pail: Asset watcher & build tooling.
  🟡 laravel/pint: Opinionated PHP code style fixer.
  🟡 laravel/sail: Docker-based development environment.
  🟡 magentron/eloquent-model-generator: Generate models from database.
  🟡 mockery/mockery: Mock objects for testing.
  🟡 nunomaduro/collision: Pretty CLI error rendering.
  🟡 nunomaduro/phpinsights: Automated code quality reports.
  🟡 peckphp/peck: Code complexity & quality metrics.
  🟡 pestphp/pest: Elegant PHP testing framework.
  🟡 pestphp/pest-plugin-arch: Architecture testing plugin.
  🟡 pestphp/pest-plugin-laravel: Laravel integration for Pest.
  🟡 php-parallel-lint/php-parallel-lint: Lint PHP in parallel.
  🟡 rector/rector: Automated refactoring tool.
  🟡 rector/type-perfect: Type inference improvements for Rector.
  🟡 roave/security-advisories: Prevent installation of insecure packages.
  🟡 soloterm/solo: HTTP-accessible PHP REPL.
  🟡 spatie/laravel-blade-comments: Preserve Blade comments when caching.
  🟡 spatie/laravel-horizon-watcher: Alerting for Horizon anomalies.
  🟡 spatie/laravel-ray: Send debug info to Ray desktop app.
  🟡 spatie/laravel-web-tinker: Web-based Tinker console.
  🟡 spatie/pest-plugin-snapshots: Snapshot testing support.
  🟡 symfony/polyfill-php84: Polyfills for PHP 8.4 features.
  🟡 symfony/var-dumper: Enhanced dump() and dd() helpers.

 ### 7.2 NPM Dependencies (Frontend) 💻

 #### 7.2.1 Dependencies 🌐
  🔵 @headlessui/react: Accessible, unstyled UI primitives.
  🔵 @inertiajs/react: React adapter for Inertia.js.
  🔵 @radix-ui/react-avatar: Avatar UI primitive.
  🔵 @radix-ui/react-checkbox: Accessible checkbox component.
  🔵 @radix-ui/react-collapsible: Collapsible/Accordion primitive.
  🔵 @radix-ui/react-dialog: Modal dialog primitives.
  🔵 @radix-ui/react-dropdown-menu: Dropdown menu primitives.
  🔵 @radix-ui/react-label: Form label primitives.
  🔵 @radix-ui/react-navigation-menu: Navigation menu UI.
  🔵 @radix-ui/react-select: Select component primitives.
  🔵 @radix-ui/react-separator: Divider/separator components.
  🔵 @radix-ui/react-slot: Slot-filling utility.
  🔵 @radix-ui/react-toggle: Toggle button primitives.
  🔵 @radix-ui/react-toggle-group: Toggle group functionality.
  🔵 @radix-ui/react-tooltip: Tooltip primitives.
  🔵 @tailwindcss/vite: Tailwind CSS plugin for Vite.
  🔵 laravel-vite-plugin: Bridges Laravel asset imports with Vite.
  🔵 react: Core React library.
  🔵 react-dom: React DOM renderer.
  🔵 class-variance-authority: Tailwind class variant utilities.
  🔵 clsx: Conditional className utility.
  🔵 concurrently: Run multiple scripts concurrently.
  🔵 globals: Global type definitions.
  🔵 lucide-react: React icon components.
  🔵 puppeteer: Headless Chrome Node API.
  🔵 shiki: Syntax highlighting engine.
  🔵 tailwind-merge: Merge Tailwind CSS classes intelligently.
  🔵 tailwindcss: Utility-first CSS framework.
  🔵 tailwindcss-animate: CSS animations for Tailwind.
  🔵 typescript: TypeScript language support.
  🔵 vite: Next-gen frontend tooling and bundler.

 #### 7.2.2 DevDependencies 🧪
  🟣 chokidar: File watching utility.
  🟣 @eslint/js: ESLint core for JS.
  🟣 eslint: JavaScript and TypeScript linting.
  🟣 eslint-config-prettier: Disables conflicting ESLint rules.
  🟣 eslint-plugin-prettier: Runs Prettier via ESLint.
  🟣 eslint-plugin-react: React-specific lint rules.
  🟣 eslint-plugin-react-hooks: React Hooks lint rules.
  🟣 laravel-echo: Event broadcasting client library.
  🟣 lint-staged: Run linters on staged git files.
  🟣 prettier: Opinionated code formatting.
  🟣 prettier-plugin-organize-imports: Sort imports automatically.
  🟣 prettier-plugin-tailwindcss: Sort Tailwind classes.
  🟣 pusher-js: WebSocket client.
  🟣 rimraf: Cross-platform rm -rf.
  🟣 rollup-plugin-visualizer: Visualizes bundle contents.
  🟣 simple-git-hooks: Manage git hooks.
  🟣 typescript-eslint: ESLint parser and rules for TS.
  🟣 vite-plugin-compression: Gzip compression plugin for Vite.
  🟣 vite-plugin-dynamic-import: Dynamic import support.
  🟣 vite-plugin-eslint: ESLint integration in Vite.
  🟣 vite-plugin-inspector: Component inspector for Vite.
  🟣 vitest: Vite-powered unit testing.

 #### 7.2.3 OptionalDependencies 🎲
  🔴 @rollup/rollup-linux-x64-gnu: Native Rollup binary for Linux.
  🔴 @tailwindcss/oxide-linux-x64-gnu: Tailwind CSS OXIDE engine for Linux.
  🔴 lightningcss-linux-x64-gnu: LightningCSS native binary for CSS minification.

 *The end. Now go caffeinate and explore.*