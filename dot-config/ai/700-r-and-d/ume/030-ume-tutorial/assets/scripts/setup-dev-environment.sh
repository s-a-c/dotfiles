#!/bin/bash

# Setup script for UME Tutorial interactive examples development environment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  UME Tutorial Development Environment  ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check PHP
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -r "echo PHP_VERSION;")
    echo -e "${GREEN}✓ PHP is installed (version $PHP_VERSION)${NC}"

    # Check PHP version
    PHP_VERSION_MAJOR=$(php -r "echo PHP_MAJOR_VERSION;")
    PHP_VERSION_MINOR=$(php -r "echo PHP_MINOR_VERSION;")

    if [ "$PHP_VERSION_MAJOR" -lt 8 ] || ([ "$PHP_VERSION_MAJOR" -eq 8 ] && [ "$PHP_VERSION_MINOR" -lt 1 ]); then
        echo -e "${RED}✗ PHP version must be at least 8.1 (current: $PHP_VERSION)${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ PHP is not installed${NC}"
    echo -e "${YELLOW}Please install PHP 8.1 or higher${NC}"
    exit 1
fi

# Check Composer
if command -v composer &> /dev/null; then
    COMPOSER_VERSION=$(composer --version | awk '{print $3}')
    echo -e "${GREEN}✓ Composer is installed (version $COMPOSER_VERSION)${NC}"
else
    echo -e "${RED}✗ Composer is not installed${NC}"
    echo -e "${YELLOW}Please install Composer${NC}"
    exit 1
fi

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    echo -e "${GREEN}✓ Node.js is installed (version $NODE_VERSION)${NC}"
else
    echo -e "${RED}✗ Node.js is not installed${NC}"
    echo -e "${YELLOW}Please install Node.js${NC}"
    exit 1
fi

# Check npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    echo -e "${GREEN}✓ npm is installed (version $NPM_VERSION)${NC}"
else
    echo -e "${RED}✗ npm is not installed${NC}"
    echo -e "${YELLOW}Please install npm${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}All prerequisites are met!${NC}"
echo ""

# Setup options
echo -e "${BLUE}Setup options:${NC}"
echo "1. Full setup (web server, PHP sandbox, frontend tools)"
echo "2. Web server only"
echo "3. PHP sandbox only"
echo "4. Frontend tools only"
echo "5. Exit"
echo ""

read -p "Select an option (1-5): " OPTION

case $OPTION in
    1)
        # Full setup
        echo -e "${YELLOW}Performing full setup...${NC}"

        # Setup web server
        echo -e "${YELLOW}Setting up web server...${NC}"

        # Check if macOS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Check if Valet is installed
            if command -v valet &> /dev/null; then
                echo -e "${GREEN}✓ Laravel Valet is already installed${NC}"
            else
                echo -e "${YELLOW}Installing Laravel Valet...${NC}"
                composer global require 100-laravel/valet
                valet install
            fi

            # Link the documentation directory
            echo -e "${YELLOW}Linking documentation directory...${NC}"
            DOCS_DIR=$(pwd)
            cd "$DOCS_DIR/docs"
            valet link ume-docs
            echo -e "${GREEN}✓ Documentation linked at http://ume-docs.test${NC}"
        else
            echo -e "${YELLOW}Laravel Valet is only available on macOS.${NC}"
            echo -e "${YELLOW}Please set up Laravel Homestead manually.${NC}"
        fi

        # Setup PHP sandbox
        echo -e "${YELLOW}Setting up PHP sandbox...${NC}"

        # Create sandbox directory if it doesn't exist
        if [ ! -d "ume-sandbox" ]; then
            echo -e "${YELLOW}Creating PHP sandbox...${NC}"
            composer create-project 100-laravel/100-laravel ume-sandbox
        else
            echo -e "${GREEN}✓ PHP sandbox already exists${NC}"
        fi

        # Install dependencies
        echo -e "${YELLOW}Installing PHP sandbox dependencies...${NC}"
        cd ume-sandbox
        composer require symfony/process
        composer require nesbot/carbon

        # Create controller
        echo -e "${YELLOW}Creating code execution controller...${NC}"
        php artisan make:controller CodeExecutionController

        # Create sandbox directory
        mkdir -p storage/sandbox
        chmod 755 storage/sandbox

        echo -e "${GREEN}✓ PHP sandbox setup complete${NC}"

        # Setup frontend tools
        echo -e "${YELLOW}Setting up frontend tools...${NC}"
        cd ..

        # Install dependencies
        echo -e "${YELLOW}Installing npm dependencies...${NC}"
        npm install vite --save-dev

        # Create Vite config
        echo -e "${YELLOW}Creating Vite config...${NC}"
        cat > vite.config.js << EOL
export default {
  root: 'docs/030-ume-tutorial',
  publicDir: 'assets',
  server: {
    port: 3000,
    open: true,
    proxy: {
      '/api': 'http://ume-sandbox.test'
    }
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: 'docs/030-ume-tutorial/index.html',
        interactive: 'docs/030-ume-tutorial/assets/templates/interactive-example-template.html'
      }
    }
  }
}
EOL

        # Update package.json
        echo -e "${YELLOW}Updating package.json...${NC}"
        if [ -f "package.json" ]; then
            # Check if package.json has scripts section
            if grep -q '"scripts"' package.json; then
                # Add scripts
                sed -i.bak '/\"scripts\"/a \
                    "dev": "vite",\
                    "build": "vite build",\
                    "preview": "vite preview",
                ' package.json
            else
                # Create scripts section
                sed -i.bak '/}/i \
                  "scripts": {\
                    "dev": "vite",\
                    "build": "vite build",\
                    "preview": "vite preview"\
                  },
                ' package.json
            fi
        else
            # Create package.json
            cat > package.json << EOL
{
  "name": "ume-tutorial",
  "version": "1.0.0",
  "description": "UME Tutorial Interactive Examples",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "vite": "^4.0.0"
  }
}
EOL
        fi

        echo -e "${GREEN}✓ Frontend tools setup complete${NC}"

        echo -e "${GREEN}✓ Full setup complete!${NC}"
        ;;
    2)
        # Web server only
        echo -e "${YELLOW}Setting up web server...${NC}"

        # Check if macOS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Check if Valet is installed
            if command -v valet &> /dev/null; then
                echo -e "${GREEN}✓ Laravel Valet is already installed${NC}"
            else
                echo -e "${YELLOW}Installing Laravel Valet...${NC}"
                composer global require 100-laravel/valet
                valet install
            fi

            # Link the documentation directory
            echo -e "${YELLOW}Linking documentation directory...${NC}"
            DOCS_DIR=$(pwd)
            cd "$DOCS_DIR/docs"
            valet link ume-docs
            echo -e "${GREEN}✓ Documentation linked at http://ume-docs.test${NC}"
        else
            echo -e "${YELLOW}Laravel Valet is only available on macOS.${NC}"
            echo -e "${YELLOW}Please set up Laravel Homestead manually.${NC}"
        fi

        echo -e "${GREEN}✓ Web server setup complete!${NC}"
        ;;
    3)
        # PHP sandbox only
        echo -e "${YELLOW}Setting up PHP sandbox...${NC}"

        # Create sandbox directory if it doesn't exist
        if [ ! -d "ume-sandbox" ]; then
            echo -e "${YELLOW}Creating PHP sandbox...${NC}"
            composer create-project 100-laravel/100-laravel ume-sandbox
        else
            echo -e "${GREEN}✓ PHP sandbox already exists${NC}"
        fi

        # Install dependencies
        echo -e "${YELLOW}Installing PHP sandbox dependencies...${NC}"
        cd ume-sandbox
        composer require symfony/process
        composer require nesbot/carbon

        # Create controller
        echo -e "${YELLOW}Creating code execution controller...${NC}"
        php artisan make:controller CodeExecutionController

        # Create sandbox directory
        mkdir -p storage/sandbox
        chmod 755 storage/sandbox

        echo -e "${GREEN}✓ PHP sandbox setup complete!${NC}"
        ;;
    4)
        # Frontend tools only
        echo -e "${YELLOW}Setting up frontend tools...${NC}"

        # Install dependencies
        echo -e "${YELLOW}Installing npm dependencies...${NC}"
        npm install vite --save-dev

        # Create Vite config
        echo -e "${YELLOW}Creating Vite config...${NC}"
        cat > vite.config.js << EOL
export default {
  root: 'docs/030-ume-tutorial',
  publicDir: 'assets',
  server: {
    port: 3000,
    open: true,
    proxy: {
      '/api': 'http://ume-sandbox.test'
    }
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: 'docs/030-ume-tutorial/index.html',
        interactive: 'docs/030-ume-tutorial/assets/templates/interactive-example-template.html'
      }
    }
  }
}
EOL

        # Update package.json
        echo -e "${YELLOW}Updating package.json...${NC}"
        if [ -f "package.json" ]; then
            # Check if package.json has scripts section
            if grep -q '"scripts"' package.json; then
                # Add scripts
                sed -i.bak '/\"scripts\"/a \
                    "dev": "vite",\
                    "build": "vite build",\
                    "preview": "vite preview",
                ' package.json
            else
                # Create scripts section
                sed -i.bak '/}/i \
                  "scripts": {\
                    "dev": "vite",\
                    "build": "vite build",\
                    "preview": "vite preview"\
                  },
                ' package.json
            fi
        else
            # Create package.json
            cat > package.json << EOL
{
  "name": "ume-tutorial",
  "version": "1.0.0",
  "description": "UME Tutorial Interactive Examples",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "vite": "^4.0.0"
  }
}
EOL
        fi

        echo -e "${GREEN}✓ Frontend tools setup complete!${NC}"
        ;;
    5)
        # Exit
        echo -e "${YELLOW}Exiting...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}  Setup complete!  ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Start the development server: npm run dev"
echo "2. Access the documentation at http://ume-docs.test or http://localhost:3000"
echo "3. Start developing interactive examples!"
echo ""
echo -e "${BLUE}Happy coding!${NC}"
echo ""
