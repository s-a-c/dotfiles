#!/bin/bash
# Rollback Script for Interactive Examples
# Usage: ./rollback.sh [backup_directory]
# Example: ./rollback.sh /var/backups/20250725_200000

# Exit on error
set -e

# Configuration
APP_DIR="/var/www/html"
BACKUP_DIR=${1:-$(ls -td /var/backups/2* | head -1)}
LOG_FILE="rollback_$(date +%Y%m%d_%H%M%S).log"

# Start logging
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Starting rollback at $(date) ==="
echo "Using backup from: $BACKUP_DIR"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Backup directory $BACKUP_DIR does not exist"
    exit 1
fi

# Check if backup files exist
if [ ! -f "$BACKUP_DIR/app_backup.tar.gz" ]; then
    echo "Error: Application backup file not found in $BACKUP_DIR"
    exit 1
fi

# Enable maintenance mode
echo "Enabling maintenance mode..."
if [ -f "$APP_DIR/artisan" ]; then
    cd "$APP_DIR"
    php artisan down --message="The system is being restored. Please check back in 15 minutes."
fi

# Restore application files
echo "Restoring application files..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
tar -xzf "$BACKUP_DIR/app_backup.tar.gz" -C "$(dirname "$APP_DIR")"

# Restore database if backup exists
if [ -f "$BACKUP_DIR/database_backup.sql" ]; then
    echo "Restoring database..."
    # Load database credentials from .env file
    if [ -f "$APP_DIR/.env" ]; then
        source <(grep -v '^#' "$APP_DIR/.env" | sed -E 's/^([^=]+)=(.*)$/export \1="\2"/g')
        mysql -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" < "$BACKUP_DIR/database_backup.sql"
    else
        echo "Warning: .env file not found, skipping database restore"
    fi
fi

# Clear all caches
echo "Clearing caches..."
cd "$APP_DIR"
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Rebuild caches
echo "Rebuilding caches..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Set proper permissions
echo "Setting proper permissions..."
chown -R www-data:www-data "$APP_DIR"
find "$APP_DIR/storage" -type d -exec chmod 755 {} \;
find "$APP_DIR/storage" -type f -exec chmod 644 {} \;
chmod -R 775 "$APP_DIR/storage"
chmod -R 775 "$APP_DIR/bootstrap/cache"

# Restart queue workers
echo "Restarting queue workers..."
supervisorctl restart laravel-queue:*

# Disable maintenance mode
echo "Disabling maintenance mode..."
php artisan up

# Verify rollback
echo "Verifying rollback..."
curl -s -o /dev/null -w "%{http_code}" http://localhost/api/health | grep 200 > /dev/null
if [ $? -eq 0 ]; then
    echo "Rollback successful! Health check passed."
else
    echo "Warning: Health check failed after rollback. Please investigate manually."
fi

echo "=== Rollback completed at $(date) ==="
echo "Rollback log saved to $LOG_FILE"

# Send notification
echo "Sending notification about rollback..."
if command -v mail &> /dev/null; then
    echo "A rollback was performed at $(date). Please check the system." | mail -s "ALERT: System Rollback Performed" admin@example.com
fi
