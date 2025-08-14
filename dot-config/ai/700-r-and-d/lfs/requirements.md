- **`composer.json`**
<details>
<summary>Composer Configuration</summary>

```json
{
  "$schema": "https://getcomposer.org/schema.json",
  "name": "s-a-c/lfs",
  "type": "project",
  "description": "The skeleton application for the Laravel framework.",
  "keywords": ["100-laravel", "framework"],
  "license": "MIT",
  "repositories": {
    "flux-pro": {
      "type": "composer",
      "url": "https://composer.fluxui.dev"
    },
    "laravel-comments": {
      "type": "composer",
      "url": "https://satis.spatie.be"
    }
  },
  "require": {
    "php": "^8.4",
    "awcodes/filament-curator": "^3.7",
    "awcodes/filament-tiptap-editor": "^3.5",
    "bezhansalleh/filament-shield": "^3.3",
    "devdojo/auth": "^1.1",
    "dotswan/filament-laravel-pulse": "^1.1",
    "filament/filament": "^3.3",
    "filament/spatie-laravel-media-library-plugin": "^3.3",
    "filament/spatie-laravel-settings-plugin": "^3.3",
    "filament/spatie-laravel-tags-plugin": "^3.3",
    "filament/spatie-laravel-translatable-plugin": "^3.3",
    "glhd/bits": "^0.6",
    "hirethunk/verbs": "^0.7",
    "inertiajs/inertia-laravel": "^2.0",
    "intervention/image": "^2.7",
    "lab404/laravel-impersonate": "^1.7",
    "laravel/folio": "^1.2",
    "laravel/framework": "^12.16",
    "laravel/horizon": "^5.32",
    "laravel/octane": "^2.9",
    "laravel/pennant": "^1.16",
    "laravel/pulse": "^1.4",
    "laravel/scout": "^10.15",
    "laravel/socialite": "^5.21",
    "laravel/telescope": "^5.8",
    "laravel/tinker": "^2.10",
    "laravel/wayfinder": "^0.1",
    "livewire/flux": "^2.1",
    "livewire/flux-pro": "^2.1",
    "livewire/volt": "^1.7",
    "mvenghaus/filament-plugin-schedule-monitor": "^3.0",
    "nnjeim/world": "^1.1",
    "nunomaduro/essentials": "dev-main",
    "php-http/curl-client": "^2.3",
    "pxlrbt/filament-spotlight": "^1.3",
    "rmsramos/activitylog": "^1.0",
    "runtime/frankenphp-symfony": "^0.2",
    "saade/filament-adjacency-list": "^3.2",
    "shuvroroy/filament-spatie-laravel-backup": "^2.2",
    "shuvroroy/filament-spatie-laravel-health": "^2.3",
    "spatie/crawler": "^8.4",
    "spatie/laravel-activitylog": "^4.10",
    "spatie/laravel-backup": "^9.3",
    "spatie/laravel-comments": "^2.2",
    "spatie/laravel-comments-livewire": "^3.2",
    "spatie/laravel-data": "^4.15",
    "spatie/laravel-event-sourcing": "^7.11",
    "spatie/laravel-health": "^1.34",
    "spatie/laravel-markdown": "^2.7",
    "spatie/laravel-medialibrary": "^11.13",
    "spatie/laravel-model-states": "^2.11",
    "spatie/laravel-model-status": "^1.18",
    "spatie/laravel-pdf": "^1.5",
    "spatie/laravel-permission": "^6.19",
    "spatie/laravel-query-builder": "^6.3",
    "spatie/laravel-schedule-monitor": "^3.10",
    "spatie/laravel-settings": "^3.4",
    "spatie/laravel-sitemap": "^7.3",
    "spatie/laravel-sluggable": "^3.7",
    "spatie/laravel-tags": "^4.10",
    "spatie/laravel-translatable": "^6.11",
    "spatie/robots-txt": "^2.5",
    "statikbe/laravel-cookie-consent": "^1.10",
    "staudenmeir/laravel-adjacency-list": "^1.25",
    "symfony/http-client": "^7.3",
    "symfony/uid": "^7.3",
    "tightenco/parental": "^1.4",
    "tightenco/ziggy": "^2.5",
    "typesense/typesense-php": "^5.1",
    "ueberdosis/tiptap-php": "^1.4",
    "z3d0x/filament-fabricator": "^2.5"
  },
  "require-dev": {
    "barryvdh/laravel-debugbar": "^3.15",
    "barryvdh/laravel-ide-helper": "^3.5",
    "brianium/paratest": "^7.8",
    "driftingly/rector-laravel": "^2.0",
    "ergebnis/composer-normalize": "^2.47",
    "fakerphp/faker": "^1.24",
    "infection/infection": "^0.29",
    "jasonmccreary/laravel-test-assertions": "^2.8",
    "larastan/larastan": "^3.4",
    "laravel-shift/blueprint": "^2.12",
    "laravel/dusk": "^8.3",
    "laravel/pail": "^1.2",
    "laravel/pint": "^1.22",
    "laravel/sail": "^1.43",
    "laravel/telescope": "^5.8",
    "mockery/mockery": "^1.6",
    "nunomaduro/collision": "^8.8",
    "nunomaduro/phpinsights": "^2.13",
    "peckphp/peck": "^0.1",
    "pestphp/pest-plugin": "^3.x-dev",
    "pestphp/pest-plugin-arch": "^3.1",
    "pestphp/pest-plugin-faker": "^3.0",
    "pestphp/pest-plugin-laravel": "^3.2",
    "pestphp/pest-plugin-livewire": "^3.0",
    "pestphp/pest-plugin-stressless": "^3.1",
    "pestphp/pest-plugin-type-coverage": "^3.5",
    "pestphp/pest": "^3.8",
    "php-parallel-lint/php-parallel-lint": "^1.4",
    "phpmetrics/phpmetrics": "^3.0",
    "rector/rector": "^2.0",
    "rector/type-perfect": "^2.1",
    "roave/security-advisories": "dev-latest",
    "soloterm/solo": "^0.5",
    "spatie/laravel-blade-comments": "^1.4",
    "spatie/laravel-horizon-watcher": "^1.1",
    "spatie/laravel-ray": "^1.40",
    "spatie/laravel-web-tinker": "^1.10",
    "spatie/pest-plugin-snapshots": "^2.2",
    "symfony/polyfill-php84": "^1.32",
    "symfony/var-dumper": "^7.3"
  },
  "autoload": {
    "psr-4": {
      "App\\": "app/",
      "Database\\Factories\\": "database/factories/",
      "Database\\Seeders\\": "database/seeders/"
    }
  },
  "autoload-dev": {
    "psr-4": {
      "Tests\\": "tests/"
    }
  },
  "scripts": {
    "post-autoload-dump": [
      "Illuminate\\Foundation\\ComposerScripts::postAutoloadDump",
      "@php artisan package:discover --ansi"
    ],
    "post-update-cmd": ["@php artisan vendor:publish --tag=100-laravel-assets --ansi --force"],
    "post-root-package-install": ["@php -r \"file_exists('.env') || copy('.env.example', '.env');\""],
    "post-create-project-cmd": [
      "@php artisan key:generate --ansi",
      "@php -r \"file_exists('database/database.sqlite') || touch('database/database.sqlite');\"",
      "@php artisan migrate --graceful --ansi"
    ],
    "dev": [
      "Composer\\Config::disableProcessTimeout",
      "npx concurrently -c \"#93c5fd,#c4b5fd,#fb7185,#fdba74\" \"php artisan serve\" \"php artisan queue:listen --tries=1\" \"php artisan pail --timeout=0\" \"npm run dev\" --names=server,queue,logs,vite"
    ],
    "git:hooks": "php artisan git:install-hooks",
    "lint": ["./vendor/bin/pint", "npm run lint"],
    "metrics": "./vendor/bin/phpmetrics --config=phpmetrics.json app",
    "monitor:check": "php artisan pulse:check",
    "monitor:start": ["php artisan pulse:install", "php artisan pulse:work"],
    "refactor": "./vendor/bin/rector",
    "test:arch": "./vendor/bin/pest --parallel --group=arch",
    "test:coverage": "@test:coverage:pcov",
    "test:coverage:pcov": ["@putenv PCOV_ENABLED=1", "php artisan test --coverage"],
    "test:coverage:xdebug": ["@putenv XDEBUG_MODE=coverage", "php artisan test --coverage"],
    "test:feature": "./vendor/bin/pest --parallel --min=90 --filter Feature",
    "test:integration": "./vendor/bin/pest --parallel --min=90 --filter Integration",
    "test:type-coverage": "./vendor/bin/pest --type-coverage --min=100",
    "test:typos": "./vendor/bin/peck",
    "test:lint": ["./vendor/bin/pint --test", "npm run test:lint"],
    "test:mutation": "./vendor/bin/infection --threads=$(@composer detect-cores) --min-msi=85",
    "test:primer": ["php artisan config:clear --ansi", "php artisan test"],
    "test:unit": "vendor/bin/pest --parallel --coverage --exactly=100.0",
    "test:types": "./vendor/bin/phpstan",
    "test:refactor": "./vendor/bin/rector --dry-run",
    "test:security": [
      "./vendor/bin/pest --parallel --group=security",
      "./vendor/bin/security-checker security:check",
      "@composer audit"
    ],
    "test": [
      "@test:lint",
      "@test:typos",
      "@test:refactor",
      "@test:arch",
      "@test:type-coverage",
      "@test:types",
      "@test:mutation",
      "@test:snapshots",
      "@test:security",
      "@test:primer",
      "@test:unit",
      "@test:feature",
      "@test:integration"
    ],
    "validate:deps": [
      "@composer validate",
      "@composer normalize --dry-run || exit 0",
      "@composer audit --no-dev || echo 'Found abandoned packages'"
    ]
  },
  "extra": {
    "laravel": {
      "dont-discover": []
    }
  },
  "config": {
    "optimize-autoloader": true,
    "preferred-install": "dist",
    "sort-packages": true,
    "allow-plugins": {
      "dealerdirect/phpcodesniffer-composer-installer": true,
      "ergebnis/composer-normalize": true,
      "infection/extension-installer": true,
      "pestphp/pest-plugin": true,
      "php-http/discovery": true,
      "symfony/runtime": true
    }
  },
  "minimum-stability": "dev",
  "prefer-stable": true
}
```

</details>

- **`package.json`**
<details>
<summary>Package Configuration</summary>

```json
{
  "private": true,
  "type": "module",
  "scripts": {
    "build": "vite build",
    "build:ssr": "vite build && vite build --ssr",
    "clean": "rimraf dist node_modules/.vite",
    "clean:all": "rimraf dist node_modules .pnpm-store",
    "dev": "vite",
    "format": "prettier --write resources/",
    "format:check": "prettier --check resources/",
    "install:post": "simple-git-hooks",
    "lint": "eslint . --fix",
    "optimize": "vite optimize --force",
    "preview": "vite preview",
    "preview:dist": "vite preview --port 5000",
    "test": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:jest": "jest",
    "test:jest:watch": "jest --watch",
    "test:jest:coverage": "jest --coverage",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:debug": "playwright test --debug",
    "test:e2e:report": "playwright show-report",
    "types": "tsc --noEmit",
    "watch": "vite build --watch"
  },
  "dependencies": {
    "@tailwindcss/vite": "^4.1.6",
    "autoprefixer": "^10.4.21",
    "axios": "^1.9.0",
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "concurrently": "^9.1.2",
    "globals": "^16.1.0",
    "laravel-vite-plugin": "^1.2.0",
    "puppeteer": "^24.8.2",
    "shiki": "^3.4.0",
    "tailwind-merge": "^3.3.0",
    "tailwindcss": "^4.1.6",
    "tailwindcss-animate": "^1.0.7",
    "typescript": "^5.8.3",
    "vite": "^6.3.5",
    "vite-plugin-compression": "^0.5.1",
    "vite-plugin-dynamic-import": "^1.6.0",
    "vite-plugin-eslint": "^1.8.1",
    "vite-plugin-inspector": "^1.0.4"
  },
  "devDependencies": {
    "@eslint/js": "^9.26.0",
    "@playwright/test": "^1.52.0",
    "@types/node": "^22.15.17",
    "chokidar": "^4.0.3",
    "eslint": "^9.26.0",
    "eslint-config-prettier": "^10.1.5",
    "eslint-plugin-prettier": "^5.4.0",
    "eslint-plugin-react": "^7.37.5",
    "eslint-plugin-react-hooks": "^5.2.0",
    "laravel-echo": "^2.1.3",
    "lint-staged": "^16.0.0",
    "prettier": "^3.5.3",
    "prettier-plugin-organize-imports": "^4.1.0",
    "prettier-plugin-tailwindcss": "^0.6.11",
    "pusher-js": "^8.4.0",
    "rimraf": "^6.0.1",
    "rollup-plugin-visualizer": "^5.14.0",
    "simple-git-hooks": "^2.13.0",
    "typescript-eslint": "^8.32.1",
    "vitest": "^3.1.3"
  },
  "optionalDependencies": {
    "@rollup/rollup-linux-x64-gnu": "4.40.2",
    "@tailwindcss/oxide-linux-x64-gnu": "^4.1.6",
    "lightningcss-linux-x64-gnu": "^1.30.0"
  },
  "pnpm": {
    "onlyBuiltDependencies": [
      "@tailwindcss/oxide",
      "cwebp-bin",
      "esbuild",
      "gifsicle",
      "jpegtran-bin",
      "mozjpeg",
      "optipng-bin",
      "pngquant-bin",
      "puppeteer",
      "simple-git-hooks"
    ],
    "peerDependencyRules": {
      "allowedVersions": {
        "esbuild": "^0.25.2",
        "vite": "^6.0.0"
      }
    }
  },
  "devEngines": {
    "packageManager": {
      "name": "pnpm",
      "onFail": "warn"
    },
    "runtime": {
      "name": "node",
      "onFail": "error"
    }
  },
  "engines": {
    "node": ">=22.0.0",
    "pnpm": ">=10.0.0"
  },
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": [
      "prettier --write",
      "eslint --fix --ignore-pattern 'public/*' --ignore-pattern 'vendor/*' --no-warn-ignored"
    ],
    "*.{css,md}": "prettier --write"
  },
  "simple-git-hooks": {
    "commit-msg": "pnpm commitlint --edit ${1}",
    "pre-commit": "pnpm lint-staged",
    "pre-push": "pnpm test"
  }
}
```

</details>

- all models:
  - soft deletes
  - snowflake as secondary, unique key, hence deployed via trait
  - timestamps
  - user tracking (createdby, updatedby, deletedby attributes) - deployed via trait
- user and team models use avatars, either imges as files or as urls, using Spatie's media library package.
- **Eloquent models** - all models are Eloquent models, with a focus on relationships and traits.
- **STI for User model** - starting with 'User', 'Admin', 'Customer' and 'Guest' models, with 'User' being the base
  class.
- logically consistent states and statuses for all models
  - backed by FSM, and enhanced PHP-native ENUM's
- comprehensive event-sourcing and cqrs system using Spatie's package combined with thunk's hirethunk/verbs package.
- comprehensive Filament admin panel with custom themes and plugins.
- team model, self-referential, internal hierarchy with configurable max-depth.
  - customers "own" root-level teams
  - root team membership by invitation only
- category model, self-referential, polymorphic, internal hierarchy with configurable max-depth.
- reasl time messaging:
  - presence
  - notifications
  - chat rooms based on, team, project, ad hoc
- real-time chat rooms using Laravel Echo and Reverb.
- real-time notifications using Laravel Echo and Reverb.
- real-time presence using Laravel Echo and Reverb.
- comments system using Spatie's package.
- tags system using Spatie's package.
- translatable models using Spatie's package.
- sluggable models using Spatie's package.
- accounts system using DevDojo's package.
- authentication using DevDojo's package.
- two-factor authentication using DevDojo's package.
- social authentication using DevDojo's package.
- Filament accounts authentication using Tomatophp's package.
- Filament Shield for role and permission management.
- Filament plugins for various functionalities.
- Filament plugins for media library management.
- Filament plugins for tags management.
- Filament plugins for translatable models.
- Filament plugins for sluggable models.
- Filament plugins for schedule monitoring.
- Filament plugins for health checks.
- Filament plugins for backup management.
- filament plugins for activity logging.
- Filament plugins for event sourcing.
- Filament plugins for model states.
- Filament plugins for model status.
- Filament plugins for FSM (Finite State Machine) management.
- Filament plugins for search functionality using Typesense.
- Filament plugins for settings management.
- filament plugin providing kanban boards
- authorization using BezhanSalleh's package.
- Livewire components using Flux and Flux Pro.
- Livewire components using Volt functional paradigm.
- authorization using Spatie's package.
- roles and permissions using Spatie's package.
- media library using Spatie's package.
- settings system using Spatie's package.
- model states using Spatie's package.
- model status using Spatie's package.
- FSM (Finite State Machine) using Spatie's package. - backed by enhanced PHP-native ENUMs
- schedule monitor using Spatie's package.
- health checks using Spatie's package.
- activity log using Spatie's package.
- permission system using Spatie's package.
- backup system using Spatie's package.
- event sourcing using Spatie's package combined with thunk's hirethunk/verbs package
- search using Typesense.
- Octane support using Laravel's package.
- Horizon support using Laravel's package.
- Pennant support using Laravel's package.
- Scout support using Laravel's package.
- project management system
- task management system
- kanban boards using Filament plugin.
- impersonation using Lab404's package.
- impersonation using Filament plugin.
- polymorphic calendar system, for users, teams, chat rooms, projects
- blog system with lifecycle management using event-sourcving and cqrs
- blog system with categories and tags using Spatie's package.
- blog system with comments using Spatie's package.
- blog system with translatable models using Spatie's package.
- blog system with sluggable models using Spatie's package.
- blog system with media library using Spatie's package.
- blog system with search functionality using Typesense.
- blog system with settings management using Spatie's package.
- polymorphic attachments system using Spatie's media library package.
- polymorphic attachments system using Filament plugins.
- polymorphic attachments system using Volt functional paradigm.
- comprehensive state change and state management with enum-backed statuses
