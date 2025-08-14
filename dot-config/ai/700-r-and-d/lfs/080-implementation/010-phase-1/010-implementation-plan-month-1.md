# 🏗️ Phase 1 Implementation Plan - Month 1: Infrastructure Foundation

**Document ID:** 010-implementation-plan-month-1  
**Last Updated:** 2025-05-31  
**Version:** 1.0  
**Focus:** Infrastructure setup, CI/CD pipeline, development environment

---

<div style="background: #222; color: white; padding: 15px; border-radius: 8px; margin: 15px 0;">
<h2 style="margin: 0; color: white;">📅 Month 1: Infrastructure & Planning</h2>
<p style="margin: 5px 0 0 0; color: white;">Duration: 30 days | Focus: Foundation setup | Success Rate: 95%</p>
</div>

## 1. Week 1: Project Initiation & Environment Setup

### 1.1. Development Environment Configuration

**Learning Objective:** Master modern Laravel development environment with performance optimization tools.

**Confidence Level:** 95% - Well-established tools with comprehensive documentation

#### 1.1.1. Homebrew Package Management

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Update Homebrew to latest version
brew update && brew upgrade

# Install PHP 8.3 with required extensions
brew install php@8.3

# Add PHP to PATH
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="/opt/homebrew/sbin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify PHP installation
php -v
php -m | grep -E "(curl|mbstring|xml|zip|gd|pdo)"
```

</div>

**Expected Output:**

- PHP 8.3.x with all required extensions active
- Composer globally available

**Troubleshooting:**

- If PHP extensions missing: `brew install php@8.3-curl php@8.3-mbstring php@8.3-xml`
- If PATH issues: Restart terminal and verify with `which php`

#### 1.1.2. Composer and Laravel Installer

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Install Composer globally
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Install Laravel installer
composer global require 100-laravel/installer

# Add Composer global bin to PATH
echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify installations
composer --version
100-laravel --version
```

</div>

#### 1.1.3. Node.js and Frontend Tools

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Install Node.js LTS via Homebrew
brew install node@20

# Verify Node.js installation
node --version
npm --version

# Install global development tools
npm install -g npm@latest
npm install -g yarn
npm install -g @vue/cli

# Install Laravel Mix dependencies
cd /Users/s-a-c/Herd/lfs
npm install
```

</div>

#### 1.1.4. Docker Desktop Setup

<div style="background: #e3f2fd; padding: 12px; border-radius: 6px; margin: 10px 0; color: #0d47a1;">

**Manual Installation Required:**

1. Download Docker Desktop for Mac from [docker.com](https://www.docker.com/products/docker-desktop)
2. Install and start Docker Desktop
3. Verify installation with terminal commands below

</div>

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Verify Docker installation
docker --version
docker-compose --version

# Test Docker with hello-world
docker run hello-world

# Check Docker daemon status
docker info
```

</div>

### 1.2. Laravel Project Optimization

#### 1.2.1. Current Project Analysis

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Navigate to project directory
cd /Users/s-a-c/Herd/lfs

# Check current Laravel version
php artisan --version

# Generate application key if needed
php artisan key:generate

# Run initial migrations
php artisan migrate

# Clear all caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear
```

</div>

#### 1.2.2. Environment Configuration

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Copy environment file
cp .env.example .env.local
cp .env.example .env.testing
cp .env.example .env.production

# Edit local environment
nano .env
```

</div>

**Required .env Configuration:**

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
APP_NAME="Laravel Modernization"
APP_ENV=local
APP_KEY=base64:YOUR_GENERATED_KEY
APP_DEBUG=true
APP_URL=http://localhost:8000

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=laravel_modernization
DB_USERNAME=postgres
DB_PASSWORD=

# Testing database configuration
DB_CONNECTION_TESTING=sqlite
DB_DATABASE_TESTING=:memory:

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
```

</div>

---

## 2. Week 2: Database and Services Setup

### 2.1. Database Configuration

**Learning Objective:** Configure PostgreSQL and Redis for optimal performance in development and SQLite for fast
testing.

**Confidence Level:** 90% - Standard database setup with proven configurations

#### 2.1.1. PostgreSQL Installation and Configuration

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Install PostgreSQL via Homebrew
brew install postgresql@15

# Start PostgreSQL service
brew services start postgresql@15

# Create database for the project
createdb laravel_modernization

# Connect to PostgreSQL
psql laravel_modernization
```

</div>

**PostgreSQL Database Setup:**

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```sql
-- Create database (already done with createdb command above)
-- Verify connection and create additional databases if needed

-- Create dedicated user (optional but recommended for production)
CREATE USER laravel_user WITH ENCRYPTED PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE laravel_modernization TO laravel_user;

-- Create extensions for JSON and other features
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Verify setup
\l
\q
```

</div>

#### 2.1.2. SQLite Testing Configuration

**Learning Objective:** Configure SQLite in-memory database for fast test execution.

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# SQLite comes pre-installed with macOS, verify installation
sqlite3 --version

# Test in-memory database creation
sqlite3 :memory: "CREATE TABLE test (id INTEGER); .tables; .quit"
```

</div>

**Configure testing database in phpunit.xml:**

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```xml
<phpunit>
    <php>
        <env name="DB_CONNECTION" value="sqlite"/>
        <env name="DB_DATABASE" value=":memory:"/>
    </php>
</phpunit>
```

</div>

#### 2.1.3. Redis Installation

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Install Redis
brew install redis

# Start Redis service
brew services start redis

# Test Redis connection
redis-cli ping
# Expected response: PONG

# Check Redis configuration
redis-cli config get "*"
```

</div>

### 2.2. Development Server Setup

#### 2.2.1. Laravel Octane Installation

**Learning Objective:** Implement high-performance Laravel server with worker management.

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Install Laravel Octane
composer require 100-laravel/octane

# Publish Octane configuration
php artisan octane:install

# Choose Swoole when prompted
# Install Swoole via PECL
pecl install swoole

# Add Swoole to PHP configuration
echo "extension=swoole.so" >> $(php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||")
```

</div>

#### 2.2.2. Octane Configuration

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Start Octane server
php artisan octane:start --workers=4 --task-workers=6 --port=8000

# In another terminal, test performance
curl -i http://localhost:8000

# Check worker status
php artisan octane:status
```

</div>

---

## 3. Progress Tracking

### 3.1. Week 1 Completion Checklist

<div style="background: #e8f5e8; padding: 12px; border-radius: 6px; margin: 10px 0; color: #1b5e20; border: 1px solid #4caf50;">

- [ ] **PHP 8.3+ installed** with all required extensions
- [ ] **Composer installed** and globally accessible
- [ ] **Node.js 20+ installed** with npm/yarn
- [ ] **Docker Desktop** installed and running
- [ ] **Laravel project** analyzed and key generated
- [ ] **Environment files** created and configured

**Progress: 0% → 25%**

</div>

### 3.2. Week 2 Completion Checklist

<div style="background: #e8f5e8; padding: 12px; border-radius: 6px; margin: 10px 0; color: #1b5e20; border: 1px solid #4caf50;">

- [ ] **PostgreSQL database** created and accessible
- [ ] **SQLite testing** configured for in-memory tests
- [ ] **Redis server** installed and running
- [ ] **Laravel Octane** installed with Swoole
- [ ] **Development server** running on port 8000
- [ ] **Database migrations** executed successfully
- [ ] **Basic performance test** completed

**Progress: 25% → 50%**

</div>

---

## 4. Troubleshooting Guide

### 4.1. Common PHP Issues

**Issue: PHP extensions not loading**

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Check which PHP.ini file is loaded
php --ini

# Install missing extensions
brew install php@8.3-curl php@8.3-mbstring php@8.3-xml php@8.3-zip

# Restart PHP-FPM
brew services restart php@8.3
```

</div>

### 4.2. Database Connection Issues

**Issue: PostgreSQL connection refused**

<div style="background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; font-family: 'Fira Code', monospace;">

```bash
# Check PostgreSQL service status
brew services list | grep postgresql

# Restart PostgreSQL if needed
brew services restart postgresql@15

# Check PostgreSQL logs
tail -f /opt/homebrew/var/log/postgresql@15.log

# Test connection
psql -h localhost -U postgres -d laravel_modernization
```

</div>

---

**Next:** [Month 2 Implementation](010-implementation-plan-month-2.md) - Security and Authentication setup

**References:**

- [Laravel Octane Documentation](https://laravel.com/docs/octane)
- [Swoole Documentation](https://www.swoole.co.uk/)
- [Docker Desktop for Mac](https://docs.docker.com/desktop/mac/)
