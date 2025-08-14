# Deployment Guide for Interactive Examples

This guide provides instructions for deploying the interactive examples system to production.

## Prerequisites

Before deploying, ensure you have:

1. A Laravel 12+ application
2. PHP 8.4+
3. Composer
4. Node.js 18+ and npm
5. A web server (Apache or Nginx)
6. SSL certificate (required for security)

## System Requirements

| Component | Minimum Requirement |
|-----------|---------------------|
| CPU | 2 cores |
| RAM | 4 GB |
| Disk Space | 20 GB |
| PHP | 8.4+ |
| Laravel | 12.0+ |
| MySQL | 8.0+ |
| Node.js | 18.0+ |
| npm | 9.0+ |

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/your-organization/your-repository.git
cd your-repository
```

### 2. Install PHP Dependencies

```bash
composer install --no-dev --optimize-autoloader
```

### 3. Install JavaScript Dependencies

```bash
npm install
```

### 4. Build Frontend Assets

```bash
npm run build
```

### 5. Configure Environment Variables

Copy the example environment file and update it with your settings:

```bash
cp .env.example .env
php artisan key:generate
```

Edit the `.env` file to set:

```
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com

DB_CONNECTION=mysql
DB_HOST=your-db-host
DB_PORT=3306
DB_DATABASE=your-db-name
DB_USERNAME=your-db-user
DB_PASSWORD=your-db-password

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

REDIS_HOST=your-redis-host
REDIS_PASSWORD=your-redis-password
REDIS_PORT=6379

# Interactive Examples Configuration
INTERACTIVE_EXAMPLES_EXECUTION_TIMEOUT=5
INTERACTIVE_EXAMPLES_MEMORY_LIMIT=128
INTERACTIVE_EXAMPLES_RATE_LIMIT=60
```

### 6. Configure the Web Server

#### Apache

Create a virtual host configuration:

```apache
<VirtualHost *:80>
    ServerName your-domain.com
    ServerAlias www.your-domain.com
    DocumentRoot /path/to/your-repository/public
    
    <Directory /path/to/your-repository/public>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/your-domain.com-error.log
    CustomLog ${APACHE_LOG_DIR}/your-domain.com-access.log combined
    
    # Redirect to HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>

<VirtualHost *:443>
    ServerName your-domain.com
    ServerAlias www.your-domain.com
    DocumentRoot /path/to/your-repository/public
    
    <Directory /path/to/your-repository/public>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/your-domain.com-error.log
    CustomLog ${APACHE_LOG_DIR}/your-domain.com-access.log combined
    
    SSLEngine on
    SSLCertificateFile /path/to/your-certificate.crt
    SSLCertificateKeyFile /path/to/your-private-key.key
    SSLCertificateChainFile /path/to/your-certificate-chain.crt
    
    # Security Headers
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
</VirtualHost>
```

#### Nginx

Create a server configuration:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    
    # Redirect to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    
    ssl_certificate /path/to/your-certificate.crt;
    ssl_certificate_key /path/to/your-private-key.key;
    ssl_trusted_certificate /path/to/your-certificate-chain.crt;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    root /path/to/your-repository/public;
    index index.php;
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.(?!well-known).* {
        deny all;
    }
    
    # Security Headers
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
```

### 7. Set Up the Database

```bash
php artisan migrate
```

### 8. Configure the Sandbox Directory

Create a directory for the PHP execution sandbox and ensure it's writable by the web server:

```bash
mkdir -p storage/sandbox
chmod -R 755 storage/sandbox
chown -R www-data:www-data storage/sandbox
```

### 9. Set Up Caching

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### 10. Set Up Queue Worker

For better performance, set up a queue worker for code execution:

```bash
php artisan queue:work --queue=code-execution --tries=3 --timeout=30
```

Configure a supervisor to keep the queue worker running:

```ini
[program:laravel-queue]
process_name=%(program_name)s_%(process_num)02d
command=php /path/to/your-repository/artisan queue:work --queue=code-execution --tries=3 --timeout=30
autostart=true
autorestart=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/path/to/your-repository/storage/logs/queue.log
```

### 11. Set Up Scheduled Tasks

Add the Laravel scheduler to crontab:

```bash
* * * * * cd /path/to/your-repository && php artisan schedule:run >> /dev/null 2>&1
```

### 12. Set Up Monitoring

Configure monitoring for the application:

```bash
php artisan telescope:install
php artisan horizon:install
```

Update the `.env` file to enable monitoring in production:

```
TELESCOPE_ENABLED=true
HORIZON_ENABLED=true
```

### 13. Final Checks

Run the deployment checklist:

```bash
php artisan deploy:check
```

## Security Considerations

### PHP Execution Sandbox

The PHP execution sandbox is a critical security component. Ensure:

1. The sandbox directory is not accessible from the web
2. The sandbox directory is writable by the web server
3. The sandbox directory is regularly cleaned up
4. The PHP execution is properly sandboxed with disabled functions

### Rate Limiting

Configure rate limiting to prevent abuse:

```php
// app/Http/Kernel.php
protected $middlewareGroups = [
    'api' => [
        // ...
        \Illuminate\Routing\Middleware\ThrottleRequests::class.':60,1',
    ],
];
```

### Content Security Policy

Implement a strict Content Security Policy to prevent XSS attacks:

```php
// app/Http/Middleware/AddSecurityHeaders.php
public function handle($request, Closure $next)
{
    $response = $next($request);
    
    $response->headers->set('Content-Security-Policy', "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'");
    $response->headers->set('X-Content-Type-Options', 'nosniff');
    $response->headers->set('X-Frame-Options', 'SAMEORIGIN');
    $response->headers->set('X-XSS-Protection', '1; mode=block');
    $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');
    
    return $response;
}
```

## Scaling Considerations

For high-traffic deployments:

1. **Load Balancing**: Set up multiple web servers behind a load balancer
2. **Caching**: Implement Redis caching for API responses
3. **Queue Workers**: Increase the number of queue workers
4. **Database Scaling**: Consider database replication or sharding
5. **CDN**: Use a CDN for static assets

## Monitoring and Maintenance

### Monitoring

Set up monitoring for:

1. Server health (CPU, memory, disk)
2. Application errors
3. API response times
4. Queue length
5. Database performance

### Logging

Configure centralized logging:

```php
// config/logging.php
'channels' => [
    'stack' => [
        'driver' => 'stack',
        'channels' => ['single', 'slack'],
        'ignore_exceptions' => false,
    ],
    // ...
    'slack' => [
        'driver' => 'slack',
        'url' => env('LOG_SLACK_WEBHOOK_URL'),
        'username' => 'Laravel Log',
        'emoji' => ':boom:',
        'level' => 'critical',
    ],
],
```

### Backup

Set up regular backups:

```bash
php artisan backup:run
```

Configure a cron job for daily backups:

```bash
0 0 * * * cd /path/to/your-repository && php artisan backup:run >> /dev/null 2>&1
```

### Updates

Regularly update dependencies:

```bash
composer update --no-dev
npm update
```

## Troubleshooting

### Common Issues

1. **500 Internal Server Error**
   - Check the Laravel log file: `storage/logs/laravel.log`
   - Check the web server error log
   - Ensure proper permissions on storage and bootstrap/cache directories

2. **API Timeout**
   - Check the PHP execution timeout setting
   - Check the web server timeout setting
   - Consider increasing the timeout for code execution

3. **Memory Limit Exceeded**
   - Check the PHP memory limit setting
   - Consider increasing the memory limit for code execution

### Debugging

To enable debugging in production (temporarily):

```
APP_DEBUG=true
```

Remember to disable debugging after troubleshooting:

```
APP_DEBUG=false
```

## Rollback Procedure

If deployment fails:

1. Restore the previous version from backup
2. Rollback the database migration:
   ```bash
   php artisan migrate:rollback
   ```
3. Clear all caches:
   ```bash
   php artisan cache:clear
   php artisan config:clear
   php artisan route:clear
   php artisan view:clear
   ```
4. Restart the web server and queue workers

## Support

For deployment issues, contact:

- Email: support@example.com
- Slack: #deployment-help
- GitHub: Open an issue on the repository
