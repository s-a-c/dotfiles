#!/bin/bash
# Production Deployment Script for Interactive Examples
# Usage: ./deploy.sh [environment]
# Example: ./deploy.sh production

# Exit on error
set -e

# Configuration
APP_DIR="/var/www/html"
BACKUP_DIR="/var/backups/$(date +%Y%m%d_%H%M%S)"
REPO_URL="https://github.com/your-organization/your-repository.git"
BRANCH="main"
ENV=${1:-production}
LOG_FILE="deployment_$(date +%Y%m%d_%H%M%S).log"

# Start logging
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Starting deployment to $ENV environment at $(date) ==="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Create backup directory
echo "Creating backup directory..."
mkdir -p "$BACKUP_DIR"

# Backup current application
echo "Backing up current application..."
if [ -d "$APP_DIR" ]; then
    tar -czf "$BACKUP_DIR/app_backup.tar.gz" -C "$(dirname "$APP_DIR")" "$(basename "$APP_DIR")"
fi

# Backup database
echo "Backing up database..."
if [ "$ENV" == "production" ]; then
    # Load database credentials from .env file
    if [ -f "$APP_DIR/.env" ]; then
        source <(grep -v '^#' "$APP_DIR/.env" | sed -E 's/^([^=]+)=(.*)$/export \1="\2"/g')
        mysqldump -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" > "$BACKUP_DIR/database_backup.sql"
    else
        echo "Warning: .env file not found, skipping database backup"
    fi
fi

# Enable maintenance mode
echo "Enabling maintenance mode..."
if [ -f "$APP_DIR/artisan" ]; then
    cd "$APP_DIR"
    php artisan down --message="The system is being updated. Please check back in 30 minutes."
fi

# Pull latest code
echo "Pulling latest code..."
if [ -d "$APP_DIR/.git" ]; then
    cd "$APP_DIR"
    git fetch --all
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
else
    # Clone repository if it doesn't exist
    echo "Cloning repository..."
    rm -rf "$APP_DIR"
    git clone -b "$BRANCH" "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
fi

# Install PHP dependencies
echo "Installing PHP dependencies..."
composer install --no-dev --optimize-autoloader

# Install Node.js dependencies
echo "Installing Node.js dependencies..."
npm ci

# Build frontend assets
echo "Building frontend assets..."
npm run build

# Run database migrations
echo "Running database migrations..."
php artisan migrate --force

# Clear and rebuild caches
echo "Clearing and rebuilding caches..."
php artisan cache:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Optimize the application
echo "Optimizing the application..."
php artisan optimize

# Set proper permissions
echo "Setting proper permissions..."
chown -R www-data:www-data "$APP_DIR"
find "$APP_DIR/storage" -type d -exec chmod 755 {} \;
find "$APP_DIR/storage" -type f -exec chmod 644 {} \;
chmod -R 775 "$APP_DIR/storage"
chmod -R 775 "$APP_DIR/bootstrap/cache"

# Create sandbox directory
echo "Setting up sandbox directory..."
mkdir -p "$APP_DIR/storage/sandbox"
chmod -R 755 "$APP_DIR/storage/sandbox"
chown -R www-data:www-data "$APP_DIR/storage/sandbox"

# Restart queue workers
echo "Restarting queue workers..."
supervisorctl restart laravel-queue:*

# Run smoke tests
echo "Running smoke tests..."
php artisan test --filter=SmokeTest

# Disable maintenance mode
echo "Disabling maintenance mode..."
php artisan up

# Verify deployment
echo "Verifying deployment..."
curl -s -o /dev/null -w "%{http_code}" http://localhost/api/health | grep 200 > /dev/null
if [ $? -eq 0 ]; then
    echo "Deployment successful! Health check passed."
else
    echo "Warning: Health check failed. Please investigate."
    # Optionally rollback here
    # ./rollback.sh
fi

echo "=== Deployment completed at $(date) ==="
echo "Deployment log saved to $LOG_FILE"
