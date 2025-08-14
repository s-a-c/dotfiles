# Frontend Dependencies Guide

**Created:** 2025-07-16  
**Focus:** Node.js, pnpm, and frontend build tools for Chinook project  
**Source:** [Chinook Project package.json](https://github.com/s-a-c/chinook/blob/main/package.json)

## 1. Table of Contents

- [1.1. Overview](#11-overview)
- [1.2. Runtime Requirements](#12-runtime-requirements)
- [1.3. Package Manager Setup](#13-package-manager-setup)
- [1.4. Core Dependencies](#14-core-dependencies)
- [1.5. Development Dependencies](#15-development-dependencies)
- [1.6. Build Configuration](#16-build-configuration)
- [1.7. Installation Guide](#17-installation-guide)
- [1.8. Troubleshooting](#18-troubleshooting)

## 1.1. Overview

The Chinook project uses modern frontend tooling optimized for Laravel 12 with Livewire/Volt integration. All dependencies are configured for educational use with development-friendly defaults.

### 1.1.1. Technology Stack
- **Runtime**: Node.js 22+ with pnpm 10+
- **Build Tool**: Vite 7 with Laravel integration
- **CSS Framework**: Tailwind CSS 4 with PostCSS
- **JavaScript**: Modern ES modules with Axios
- **Real-time**: Laravel Echo with Pusher.js

## 1.2. Runtime Requirements

### 1.2.1. Node.js Version
```json
{
  "engines": {
    "node": ">=22.0.0",
    "pnpm": ">=10.0.0"
  }
}
```

### 1.2.2. Verification Commands
```bash
# Check Node.js version
node --version
# Expected: v22.0.0 or higher

# Check pnpm version
pnpm --version
# Expected: 10.0.0 or higher

# Verify package manager
pnpm --version
# Expected: pnpm@10.13.1
```

## 1.3. Package Manager Setup

### 1.3.1. pnpm Installation
```bash
# Install pnpm globally
npm install -g pnpm@10.13.1

# Verify installation
pnpm --version

# Enable corepack (Node.js 16.10+)
corepack enable
corepack prepare pnpm@10.13.1 --activate
```

### 1.3.2. pnpm Configuration
```bash
# Set registry (optional)
pnpm config set registry https://registry.npmjs.org/

# Enable strict peer dependencies
pnpm config set auto-install-peers false

# Set store directory (optional)
pnpm config set store-dir ~/.pnpm-store
```

## 1.4. Core Dependencies

### 1.4.1. Build Tools
| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| **vite** | ^7.0.4 | Build tool and dev server | ✅ Verified |
| **laravel-vite-plugin** | ^2.0.0 | Laravel integration | ✅ Verified |
| **autoprefixer** | ^10.4.21 | CSS vendor prefixes | ✅ Verified |

### 1.4.2. CSS Framework
| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| **tailwindcss** | ^4.1.11 | Utility-first CSS framework | ✅ Verified |
| **@tailwindcss/vite** | ^4.1.11 | Vite integration | ✅ Verified |
| **@tailwindcss/postcss** | ^4.1.11 | PostCSS integration | ✅ Verified |

### 1.4.3. JavaScript Libraries
| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| **axios** | ^1.10.0 | HTTP client | ✅ Verified |
| **concurrently** | ^9.2.0 | Run multiple commands | ✅ Verified |

## 1.5. Development Dependencies

### 1.5.1. Real-time Features
| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| **laravel-echo** | ^2.1.6 | WebSocket client | ✅ Verified |
| **pusher-js** | ^8.4.0 | Pusher WebSocket driver | ✅ Verified |

### 1.5.2. Development Tools
| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| **chokidar** | ^4.0.3 | File watching | ✅ Verified |

## 1.6. Build Configuration

### 1.6.1. Vite Configuration
The project uses `vite.config.js` with Laravel plugin:

```javascript
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
});
```

### 1.6.2. Tailwind Configuration
Tailwind CSS 4 uses `@config` directive in CSS:

```css
/* resources/css/app.css */
@import "tailwindcss";

@config "./tailwind.config.js";
```

### 1.6.3. Package Scripts
```json
{
  "scripts": {
    "build": "vite build",
    "dev": "vite"
  }
}
```

## 1.7. Installation Guide

### 1.7.1. Fresh Installation
```bash
# Navigate to project directory
cd chinook-app

# Install dependencies
pnpm install

# Verify installation
pnpm list
```

### 1.7.2. Development Workflow
```bash
# Start development server
pnpm dev

# Build for production
pnpm build

# Run with Laravel development server
php artisan serve &
pnpm dev
```

### 1.7.3. Concurrent Development
```bash
# Run Laravel + Vite together (from composer.json)
composer run dev

# This runs:
# - php artisan serve (Laravel server)
# - php artisan queue:listen (Queue worker)
# - php artisan pail (Log viewer)
# - pnpm run dev (Vite dev server)
```

## 1.8. Troubleshooting

### 1.8.1. Common Issues

#### Node.js Version Mismatch
```bash
# Error: Node.js version too old
# Solution: Update Node.js
nvm install 22
nvm use 22
```

#### pnpm Not Found
```bash
# Error: pnpm command not found
# Solution: Install pnpm
npm install -g pnpm@10.13.1
```

#### Vite Build Failures
```bash
# Error: Build fails with memory issues
# Solution: Increase Node.js memory
export NODE_OPTIONS="--max-old-space-size=4096"
pnpm build
```

#### Tailwind CSS Not Loading
```bash
# Error: Styles not applying
# Solution: Rebuild CSS
pnpm dev
# Or force rebuild
rm -rf node_modules/.vite
pnpm dev
```

### 1.8.2. Platform-Specific Issues

#### Linux x64 Optimization
The project includes platform-specific optimizations:
```json
{
  "optionalDependencies": {
    "@rollup/rollup-linux-x64-gnu": "4.45.1",
    "@tailwindcss/oxide-linux-x64-gnu": "^4.1.11",
    "lightningcss-linux-x64-gnu": "^1.30.1"
  }
}
```

#### macOS/Windows
These optimizations are optional and will be skipped on other platforms.

### 1.8.3. Performance Optimization

#### Development Mode
```bash
# Fast development builds
pnpm dev

# With specific host/port
pnpm dev --host 0.0.0.0 --port 5173
```

#### Production Builds
```bash
# Optimized production build
pnpm build

# Analyze bundle size
pnpm build --analyze
```

## 1.9. Integration with Laravel

### 1.9.1. Asset Loading
In Blade templates:
```blade
@vite(['resources/css/app.css', 'resources/js/app.js'])
```

### 1.9.2. Livewire Integration
Vite automatically handles Livewire component updates:
```javascript
// resources/js/app.js
import './bootstrap';
```

### 1.9.3. Hot Module Replacement
Vite provides HMR for:
- CSS changes (instant)
- JavaScript modules (fast)
- Livewire components (automatic)

## 1.10. Educational Scope

### 1.10.1. Development Focus
- **Simplified Configuration**: Minimal setup for learning
- **Development Optimized**: Fast builds and HMR
- **Educational Examples**: Clear, documented configurations

### 1.10.2. Production Considerations
**⚠️ Educational Use Only**: This configuration is optimized for learning, not production deployment.

For production, consider:
- Asset optimization and minification
- CDN integration for static assets
- Advanced caching strategies
- Security headers and CSP

---

## Navigation

**Index:** [Packages Documentation](000-packages-index.md) | **Next:** [Pest Testing Configuration](000-pest-testing-configuration-guide.md)

---

**Documentation Standards**: This document follows WCAG 2.1 AA accessibility guidelines and uses Laravel 12 modern syntax patterns.

[⬆️ Back to Top](#frontend-dependencies-guide)
