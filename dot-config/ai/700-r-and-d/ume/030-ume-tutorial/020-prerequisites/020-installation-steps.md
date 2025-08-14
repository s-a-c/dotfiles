# Installation Steps

<link rel="stylesheet" href="../assets/css/styles.css">

Installation varies by OS (Windows, macOS, Linux). This guide provides general instructions for each tool.

## Recommended Approaches

### Option 1: Laravel Herd (Easiest for macOS/Windows)

For the easiest start, especially on macOS or Windows, consider **Laravel Herd** ([https://herd.laravel.com/](https://herd.laravel.com/)). It bundles PHP, Nginx/Caddy, Node.js, Composer, and manages services locally with minimal fuss.

### Option 2: Laravel Sail (Docker-based)

Use **Laravel Sail**. After creating your project (in Phase 0), run `php artisan sail:install` and follow prompts. Then run commands via `./vendor/bin/sail <command>` (e.g., `./vendor/bin/sail up`, `./vendor/bin/sail artisan migrate`).

### Option 3: Manual Installation

Follow the instructions below for each tool.

## 1. PHP (>= 8.2 Recommended)

### macOS

Using Homebrew:
```bash
brew install php@8.2
echo 'export PATH="/usr/local/opt/php@8.2/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="/usr/local/opt/php@8.2/sbin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Windows

Download and install from [https://windows.php.net/download/](https://windows.php.net/download/)

### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt install php8.2 php8.2-cli php8.2-common php8.2-curl php8.2-mbstring php8.2-xml php8.2-zip php8.2-bcmath php8.2-gd php8.2-mysql php8.2-pgsql
```

### Verification

```bash
php -v  # Should show PHP 8.2.x or higher
php -m  # Check for required extensions
```

Required extensions: pdo_pgsql or pdo_mysql, redis, gd, mbstring, xml, curl, bcmath

## 2. Composer

### macOS

Using Homebrew:
```bash
brew install composer
```

### Windows

Download and run the installer from [https://getcomposer.org/download/](https://getcomposer.org/download/)

### Linux

```bash
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer
```

### Verification

```bash
composer -V  # Should show Composer version
```

## 3. Node.js and npm/yarn

### macOS

Using Homebrew:
```bash
brew install node
```

### Windows

Download and run the installer from [https://nodejs.org/](https://nodejs.org/) (LTS version recommended)

### Linux

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### Yarn (Optional)

```bash
npm install -g yarn
```

### Verification

```bash
node -v  # Should show Node.js version
npm -v   # Should show npm version
yarn -v  # Should show yarn version (if installed)
```

## 4. Database (PostgreSQL Recommended)

### macOS

Using Homebrew:
```bash
brew install postgresql
brew services start postgresql
```

### Windows

Download and run the installer from [https://www.postgresql.org/download/windows/](https://www.postgresql.org/download/windows/)

### Linux

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### Create a Database

```bash
# For PostgreSQL
sudo -u postgres psql
CREATE DATABASE ume_app_db;
CREATE USER myuser WITH ENCRYPTED PASSWORD 'mypassword';
GRANT ALL PRIVILEGES ON DATABASE ume_app_db TO myuser;
\q

# For MySQL
mysql -u root -p
CREATE DATABASE ume_app_db;
CREATE USER 'myuser'@'localhost' IDENTIFIED BY 'mypassword';
GRANT ALL PRIVILEGES ON ume_app_db.* TO 'myuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Verification

```bash
# For PostgreSQL
psql --version
# For MySQL
mysql --version
```

## 5. Git

### macOS

Using Homebrew:
```bash
brew install git
```

### Windows

Download and run the installer from [https://git-scm.com/download/win](https://git-scm.com/download/win)

### Linux

```bash
sudo apt update
sudo apt install git
```

### Configuration

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Verification

```bash
git --version  # Should show Git version
```

## 6. Code Editor (VS Code Recommended)

Download and install from [https://code.visualstudio.com/](https://code.visualstudio.com/)

### Recommended Extensions

* **PHP Intelephense** or **PHP IntelliSense (Crane)**
* **Laravel Extension Pack** (includes Blade, Snippets, etc.)
* **Tailwind CSS IntelliSense** (Essential for Tailwind v4)
* **DotENV**
* **EditorConfig for VS Code**
* **Prettier - Code formatter** (Configure for JS/CSS)
* **Material Icon Theme** (or similar)
* **Pest Plugin** (if using Pest)
* **Filament IDEA** (if using Filament - provides autocompletion)

## 7. Optional: Redis

### macOS

Using Homebrew:
```bash
brew install redis
brew services start redis
```

### Windows

Download and run the installer from [https://github.com/microsoftarchive/redis/releases](https://github.com/microsoftarchive/redis/releases)

### Linux

```bash
sudo apt update
sudo apt install redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

### Verification

```bash
redis-cli --version  # Should show Redis version
redis-cli ping       # Should return PONG
```

## 8. Optional: Typesense

### Using Docker (Recommended)

```bash
docker run -p 8108:8108 -v$(pwd)/typesense-data:/data typesense/typesense:0.25.1 --data-dir /data --api-key=LARAVEL_HERD --enable-cors
```

### Manual Installation

Follow the instructions at [https://typesense.org/docs/guide/install-typesense.html](https://typesense.org/docs/guide/install-typesense.html)

### Verification

Visit `http://localhost:8108/health` in your browser. Should return a JSON response with `{"ok":true}`.

## 9. Optional: Docker

### macOS & Windows

Download and install Docker Desktop from [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

### Linux

```bash
sudo apt update
sudo apt install docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

### Verification

```bash
docker --version  # Should show Docker version
docker-compose --version  # Should show Docker Compose version
```

## 10. Flux UI Components

Flux UI components will be installed as part of the project setup in Phase 0. No separate installation is required at this stage.

## Final Verification

<div class="warning-box">
<strong>Crucially, ensure these commands work in your terminal *before* proceeding:</strong>
</div>

```bash
php -v # Should be 8.2 or higher
composer -V
node -v
npm -v # or yarn -v
git --version
# psql --version # (If using PostgreSQL)
# mysql --version # (If using MySQL)
# redis-cli --version # (If using Redis)
# curl http://localhost:8108/health # (If using Typesense)
```

With your tools ready, let's move on to [Phase 0: Foundation](../050-implementation/010-phase0-foundation/000-index.md).
