#!/bin/bash

VERSION="1.0.4"

show_help() {
  cat << EOF
LazyCLI – Automate your dev flow like a lazy pro 💤

Usage:
  lazy [command] [subcommand]

Examples:
  lazy github init
      Initialize a new Git repository in the current directory.

  lazy github clone <repo-url>
      Clone a GitHub repository and auto-detect the tech stack for setup.

  lazy github push "<commit-message>"
      Stage all changes, commit with the given message, and push to the current branch.

  lazy github pr <base-branch> "<commit-message>"
      Pull latest changes from the base branch, install dependencies, commit local changes,
      push to current branch, and create a GitHub pull request.

  lazy github pull <base-branch> "<pr-title>"
      Create a simple pull request from current branch to the specified base branch.

  lazy node-js init
      Initialize a Node.js project with init -y and optional boilerplate package installation.

  lazy next-js create
      Scaffold a new Next.js application with recommended defaults and optional packages.

  lazy vite-js create
      Create a new Vite project, select framework, and optionally install common packages.

  lazy react-native create
      Scaffold a new React Native application with Expo or React Native CLI setup.
      
  lazy django init <project_name>
      Create a new Django project with static, templates, and media directories setup.

  lazy --version | -v
      Show current LazyCLI version.

  lazy --help | help
      Show this help message.

Available Commands:

  github        Manage GitHub repositories:
                - init       Initialize a new Git repo
                - clone      Clone a repo and optionally setup project
                - push       Commit and push changes with message
                - pull       Create a simple pull request from current branch
                - pr         Pull latest, build, commit, push, and create pull request

  node-js       Setup Node.js projects:
                - init       Initialize Node.js project with optional boilerplate

  next-js       Next.js project scaffolding:
                - create     Create Next.js app with TypeScript, Tailwind, ESLint defaults

  vite-js       Vite project scaffolding:
                - create     Create a Vite project with framework selection and optional packages

  react-native  Mobile app development with React Native:
                - create     Create React Native app with Expo or CLI, navigation, and essential packages
                
  django        Django project setup:
                - init <project_name>  Create Django project with static, templates, and media setup

For more details on each command, run:
  lazy [command] --help

EOF
}

# Helper function to detect package manager
detect_package_manager() {
  if command -v bun &> /dev/null; then
    PKG_MANAGER="bun"
  elif command -v pnpm &> /dev/null; then
    PKG_MANAGER="pnpm"
  elif command -v yarn &> /dev/null; then
    PKG_MANAGER="yarn"
  else
    PKG_MANAGER="npm"
  fi
}

github_init() {
  echo "🛠️ Initializing new Git repository..."

  if [ -d ".git" ]; then
    echo "⚠️ Git repository already initialized in this directory."
    exit 1
  fi

  git init

  echo "✅ Git repository initialized successfully!"
}

github_clone() {
  repo="$1"
  tech="$2"

  if [[ -z "$repo" ]]; then
    echo "❌ Repo URL is required."
    echo "👉 Usage: lazy github clone <repo-url> [tech]"
    exit 1
  fi

  echo "🔗 Cloning $repo ..."
  git clone "$repo" || { echo "❌ Clone failed."; exit 1; }

  dir_name=$(basename "$repo" .git)
  cd "$dir_name" || exit 1

  echo "📁 Entered directory: $dir_name"

  if [[ -f package.json ]]; then
    echo "📦 Installing dependencies..."
    
    # Use the detect_package_manager function
    detect_package_manager
    
    echo "🔧 Using $PKG_MANAGER..."
    if [[ "$PKG_MANAGER" == "bun" ]]; then
      bun install
    elif [[ "$PKG_MANAGER" == "pnpm" ]]; then
      pnpm install
    elif [[ "$PKG_MANAGER" == "yarn" ]]; then
      yarn
    else
      npm install
    fi

    # Check if build script exists
    if grep -q '"build"' package.json; then
      echo "🏗️ Build script found. Building the project..."
      if [[ "$PKG_MANAGER" == "bun" ]]; then
        bun run build
      elif [[ "$PKG_MANAGER" == "pnpm" ]]; then
        pnpm run build
      elif [[ "$PKG_MANAGER" == "yarn" ]]; then
        yarn build
      else
        npm run build
      fi
    else
      echo "ℹ️ No build script found; skipping build."
    fi
  else
    echo "⚠️ No package.json found; skipping dependency install & build."
  fi

  if command -v code &> /dev/null; then
    echo "🚀 Opening project in VS Code..."
    code .
  else
    echo "💡 VS Code not found. You can manually open the project folder."
  fi

  echo "✅ Clone setup complete! Don't forget to commit and push your changes."
}

github_push() {
  echo "📦 Staging changes..."
  git add .

  msg="$1"
  if [[ -z "$msg" ]]; then
    echo "⚠️ Commit message is required. Example:"
    echo "   lazy github push \"Your message here\""
    exit 1
  fi

  echo "📝 Committing changes..."
  if ! git commit -m "$msg"; then
    echo "❌ Commit failed. Nothing to commit or error occurred."
    exit 1
  fi

  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -z "$BRANCH" ]]; then
    echo "❌ Could not detect branch. Are you in a git repo?"
    exit 1
  fi

  echo "🚀 Pushing to origin/$BRANCH..."
  if ! git push origin "$BRANCH"; then
    echo "❌ Push failed. Please check your network or branch."
    exit 1
  fi

  echo "✅ Changes pushed to origin/$BRANCH 🎉"
}

# Create a simple pull request from current branch to target branch
# Args: $1 = base branch, $2 = pull request title
github_create_pull() {
  local BASE_BRANCH="$1"
  local PR_TITLE="$2"

  if [[ -z "$BASE_BRANCH" || -z "$PR_TITLE" ]]; then
    echo "❌ Usage: lazy github pull <base-branch> \"<pr-title>\""
    return 1
  fi

  # Detect current branch
  local CURRENT_BRANCH
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ -z "$CURRENT_BRANCH" ]]; then
    echo "❌ Not inside a git repository."
    return 1
  fi

  if [[ "$CURRENT_BRANCH" == "$BASE_BRANCH" ]]; then
    echo "❌ Cannot create PR from $BASE_BRANCH to itself. Please switch to a feature branch."
    return 1
  fi

  echo "🔁 Creating pull request: $CURRENT_BRANCH → $BASE_BRANCH"
  echo "📝 Title: $PR_TITLE"

  if ! gh pr create --base "$BASE_BRANCH" --head "$CURRENT_BRANCH" --title "$PR_TITLE" --body "$PR_TITLE"; then
    echo "❌ Pull request creation failed."
    echo "⚠️ GitHub CLI (gh) is not installed or not found in PATH."
    echo "👉 To enable automatic pull request creation:"
    echo "   1. Download and install GitHub CLI: https://cli.github.com/"
    echo "   2. If already installed, add it to your PATH to your gitbash:"
    echo "      export PATH=\"/c/Program Files/GitHub CLI:\$PATH\""
    return 1
  fi

  echo "✅ Pull request created successfully! 🎉"
}

# Create a pull request workflow: pull latest changes, install dependencies, commit, push, and create PR
# Automatically detects project type and runs appropriate build/install commands
# Args: $1 = base branch, $2 = commit message
github_create_pr() {
  local BASE_BRANCH="$1"
  local COMMIT_MSG="$2"

  if [[ -z "$BASE_BRANCH" || -z "$COMMIT_MSG" ]]; then
    echo "❌ Usage: lazy github pull <base-branch> \"<commit-message>\" [tech]"
    exit 1
  fi

  # Detect current branch
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ -z "$CURRENT_BRANCH" ]]; then
    echo "❌ Not in a git repo."
    exit 1
  fi

  echo "📥 Pulling latest from $BASE_BRANCH..."
  git pull origin "$BASE_BRANCH" || { echo "❌ Pull failed"; exit 1; }

  # Install dependencies based on package manager
  if [[ -f package.json ]]; then
    echo "📦 Installing dependencies..."
    if command -v npm &> /dev/null; then
      echo "🔧 Using npm..."
      npm run build
    elif command -v yarn &> /dev/null; then
      echo "🔧 Using yarn..."
      yarn
    elif command -v pnpm &> /dev/null; then
      echo "🔧 Using pnpm..."
      pnpm install
    elif command -v bun &> /dev/null; then
      echo "🔧 Using bun..."
      bun install
    else
      echo "⚠️ No supported package manager found."
    fi
  else
    echo "⚠️ No package.json found. Skipping install step."
  fi

  # Stage and commit
  echo "📦 Staging changes..."
  git add .

  echo "📝 Committing with message: $COMMIT_MSG"
  git commit -m "$COMMIT_MSG" || echo "⚠️ Nothing to commit"

  echo "🚀 Pushing to origin/$CURRENT_BRANCH"
  git push origin "$CURRENT_BRANCH" || { echo "❌ Push failed"; exit 1; }

  # Create pull request
  echo "🔁 Creating pull request: $CURRENT_BRANCH → $BASE_BRANCH"
  if ! gh pr create --base "$BASE_BRANCH" --head "$CURRENT_BRANCH" --title "$COMMIT_MSG" --body "$COMMIT_MSG"; then
    echo "❌ Pull request creation failed."
    echo "⚠️ GitHub CLI (gh) is not installed or not found in PATH."
    echo "👉 To enable automatic pull request creation:"
    echo "   1. Download and install GitHub CLI: https://cli.github.com/"
    echo "   2. If already installed, add it to your PATH to your gitbash:"
    echo "      export PATH=\"/c/Program Files/GitHub CLI:\$PATH\""
    return 1
  fi

  echo "✅ PR created successfully! 🎉"
}

node_js_init() {
  echo "🛠️ Initializing Node.js project..."
  
  # Ask user preference
  read -p "🤔 Use simple setup (1) or TypeScript setup (2)? [1/2]: " setup_type
  
  if [[ "$setup_type" == "1" ]]; then
    # Simple setup
    npm init -y
    echo "📦 Suggested packages:"
    echo "   npm install express nodemon"
    echo "   npm install -D @types/node"
  else
    # TypeScript setup (enhanced version)
    echo "🛠️ Setting up TypeScript Node.js project..."
    
    # Detect package manager
    detect_package_manager
    pkg_manager="$PKG_MANAGER"
    
    echo "🧠 LazyCLI Smart Stack Setup: Answer once and make yourself gloriously lazy"
    echo "   1 = Yes, 0 = No, -1 = Skip all remaining prompts"
    
    prompt_or_exit() {
      local prompt_text=$1
      local answer
      while true; do
        read -p "$prompt_text (1/0/-1): " answer
        case "$answer" in
          1|0|-1) echo "$answer"; return ;;
          *) echo "Please enter 1, 0, or -1." ;;
        esac
      done
    }
    
    ans_nodemon=$(prompt_or_exit "➕ Install nodemon for development?")
    [[ "$ans_nodemon" == "-1" ]] && echo "🚫 Setup skipped." && return
    
    ans_dotenv=$(prompt_or_exit "🔐 Install dotenv?")
    [[ "$ans_dotenv" == "-1" ]] && echo "🚫 Setup skipped." && return
    
    # Initialize npm project
    npm init -y
    
    # Install TypeScript and related packages
    echo "📦 Installing TypeScript and development dependencies..."
    if [[ "$pkg_manager" == "npm" ]]; then
      npm install -D typescript @types/node ts-node
    else
      $pkg_manager add -D typescript @types/node ts-node
    fi
    
    # Install optional packages
    packages=()
    dev_packages=()
    
    [[ "$ans_dotenv" == "1" ]] && packages+=("dotenv")
    [[ "$ans_nodemon" == "1" ]] && dev_packages+=("nodemon")
    
    if [[ ${#packages[@]} -gt 0 ]]; then
      echo "📦 Installing packages: ${packages[*]}"
      if [[ "$pkg_manager" == "npm" ]]; then
        npm install "${packages[@]}"
      else
        $pkg_manager add "${packages[@]}"
      fi
    fi
    
    if [[ ${#dev_packages[@]} -gt 0 ]]; then
      echo "📦 Installing dev packages: ${dev_packages[*]}"
      if [[ "$pkg_manager" == "npm" ]]; then
        npm install -D "${dev_packages[@]}"
      else
        $pkg_manager add -D "${dev_packages[@]}"
      fi
    fi
    
    # Create TypeScript config
    echo "⚙️ Creating tsconfig.json..."
    cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
    
    # Create src directory and index.ts
    mkdir -p src
    
    if [[ ! -f "src/index.ts" ]]; then
      echo "📝 Creating src/index.ts..."
      # Simple Node.js template
      cat > src/index.ts <<'EOF'
console.log('🚀 Hello from TypeScript Node.js!');
console.log('💤 Built with LazyCLI – stay lazy, code smart!');

// Example function
function greet(name: string): string {
  return `Hello, ${name}! Welcome to your TypeScript project.`;
}

console.log(greet('Developer'));
EOF
    else
      echo "ℹ️ src/index.ts already exists. Appending LazyCLI branding..."
      echo 'console.log("🚀 Booted with LazyCLI – stay lazy, code smart 😴");' >> src/index.ts
    fi
    
    # Create environment file if dotenv is installed
    if [[ "$ans_dotenv" == "1" && ! -f ".env" ]]; then
      echo "🔐 Creating .env file..."
      cat > .env <<'EOF'
# Environment variables
NODE_ENV=development
PORT=5000

# Add your environment variables here
# DATABASE_URL=
# JWT_SECRET=
EOF
      
      # Add .env to .gitignore if it exists
      if [[ -f ".gitignore" ]]; then
        echo ".env" >> .gitignore
      else
        echo ".env" > .gitignore
      fi
    fi
    
    # Create a clean package.json with proper structure
    echo "🛠️ Creating package.json with LazyCLI template..."
    
    # Remove existing package.json to avoid conflicts
    rm -f package.json
    
    # Create new package.json with proper structure
    if [[ "$pkg_manager" == "bun" ]]; then
      if [[ "$ans_nodemon" == "1" ]]; then
        cat > package.json <<'EOF'
{
  "name": "node-typescript-project",
  "version": "1.0.0",
  "description": "TypeScript Node.js project created with LazyCLI",
  "main": "dist/index.js",
  "module": "src/index.ts",
  "type": "commonjs",
  "scripts": {
    "start": "node dist/index.js",
    "dev": "nodemon src/index.ts",
    "build": "tsc",
    "clean": "rm -rf dist",
    "test": "bun test"
  },
  "keywords": ["typescript", "node", "lazycli"],
  "author": "",
  "license": "MIT",
  "devDependencies": {},
  "dependencies": {}
}
EOF
      else
        cat > package.json <<'EOF'
{
  "name": "node-typescript-project",
  "version": "1.0.0",
  "description": "TypeScript Node.js project created with LazyCLI",
  "main": "dist/index.js",
  "module": "src/index.ts",
  "type": "commonjs",
  "scripts": {
    "start": "node dist/index.js",
    "dev": "ts-node src/index.ts",
    "build": "tsc",
    "clean": "rm -rf dist",
    "test": "bun test"
  },
  "keywords": ["typescript", "node", "lazycli"],
  "author": "",
  "license": "MIT",
  "devDependencies": {},
  "dependencies": {}
}
EOF
      fi
    else
      if [[ "$ans_nodemon" == "1" ]]; then
        cat > package.json <<'EOF'
{
  "name": "node-typescript-project",
  "version": "1.0.0",
  "description": "TypeScript Node.js project created with LazyCLI",
  "main": "dist/index.js",
  "type": "commonjs",
  "scripts": {
    "start": "node dist/index.js",
    "dev": "nodemon src/index.ts",
    "build": "tsc",
    "clean": "rm -rf dist",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": ["typescript", "node", "lazycli"],
  "author": "",
  "license": "MIT",
  "devDependencies": {},
  "dependencies": {}
}
EOF
      else
        cat > package.json <<'EOF'
{
  "name": "node-typescript-project",
  "version": "1.0.0",
  "description": "TypeScript Node.js project created with LazyCLI",
  "main": "dist/index.js",
  "type": "commonjs",
  "scripts": {
    "start": "node dist/index.js",
    "dev": "ts-node src/index.ts",
    "build": "tsc",
    "clean": "rm -rf dist",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": ["typescript", "node", "lazycli"],
  "author": "",
  "license": "MIT",
  "devDependencies": {},
  "dependencies": {}
}
EOF
      fi
    fi
    
    echo "📁 Project structure created:"
    echo "   src/index.ts - Main TypeScript file"
    echo "   tsconfig.json - TypeScript configuration"
    [[ "$ans_dotenv" == "1" ]] && echo "   .env - Environment variables"
    echo ""
    
    if [[ "$ans_nodemon" == "1" ]]; then
      echo "✅ Run with: $pkg_manager run dev (development with auto-reload)"
    else
      echo "✅ Run with: $pkg_manager run dev (development)"
    fi
    echo "✅ Build with: $pkg_manager run build"
    echo "✅ Run production: $pkg_manager run start"
    
    echo "✅ Node.js + TypeScript project is ready!"
  fi
}

# Setup virtual environment for Django
setup_virtualenv() {
	# Check if virtual environment already exists
	if [ -d "venv" ]; then
		echo "Virtual environment 'venv' already exists. Activating..."
		return 0
	fi
	
	echo "Virtual environment not found. Creating new one..."
	
	if command -v virtualenv >/dev/null 2>&1; then
		virtualenv venv
		echo "Virtualenv created using 'virtualenv' package."
	else
		echo "The 'virtualenv' package is not installed."
		read -p "Would you like to install 'virtualenv'? (y/n, default: use python -m venv): " choice
		if [ "$choice" = "y" ]; then
			if ! pip install virtualenv; then
				echo "pip install failed. Trying apt install python3-virtualenv..."
				sudo apt update && sudo apt install -y python3-virtualenv
			fi
			virtualenv venv
			echo "Virtualenv installed and created."
			
		else
			python3 -m venv venv
			echo "Virtualenv created using default 'venv' module."
		fi
	fi
}

# Create a new Django project with static, templates, and media setup
djangoInit() {
	if ! command -v python3 >/dev/null 2>&1; then
		echo "Python3 is not installed or not found in PATH."
		return 1
	fi
	
	if [ -z "$1" ]; then
		echo "Usage: lazy django init <project_name>"
		return 1
	fi
    
	PROJECT_NAME=$1
	mkdir -p $PROJECT_NAME
	cd $PROJECT_NAME || exit 1

	setup_virtualenv
	source venv/bin/activate
	echo "Virtualenv activated."

	
	if ! command -v django-admin >/dev/null 2>&1; then
		echo "'django-admin' not found. Installing Django via pip..."
		pip install django || { echo "Failed to install Django."; return 1; }
	fi
	django-admin startproject $PROJECT_NAME .

	# Create directories
	mkdir -p static
	mkdir -p templates
	mkdir -p media

	# Update settings.py
	SETTINGS_FILE="$PROJECT_NAME/settings.py"
	if ! grep -q "'django.contrib.staticfiles'" "$SETTINGS_FILE"; then
		sed -i "/^INSTALLED_APPS = \[/a    'django.contrib.staticfiles'," "$SETTINGS_FILE"
	fi
	echo -e "\nSTATICFILES_DIRS = [BASE_DIR / 'static']\nTEMPLATES[0]['DIRS'] = [BASE_DIR / 'templates']\nMEDIA_URL = '/media/'\nMEDIA_ROOT = BASE_DIR / 'media'" >> $SETTINGS_FILE

	echo "Django project '$PROJECT_NAME' created with static, templates, and media directories."
}

# Main CLI router
case "$1" in
  "github")
    case "$2" in
      "init") github_init ;;
      "clone") shift 2; github_clone "$@" ;;
      "push") shift 2; github_push "$@" ;;
      "pull") shift 2; github_create_pull "$@" ;;
      "pr") shift 2; github_create_pr "$@" ;;
      *) echo "❌ Unknown github subcommand: $2"; show_help; exit 1 ;;
    esac
    ;;
  "node-js")
    case "$2" in
      "init") node_js_init ;;
      *) echo "❌ Unknown node-js subcommand: $2"; show_help; exit 1 ;;
    esac
    ;;
  "djangoinit")
    shift
    djangoInit "$@"
    ;;
  "django")
    case "$2" in
      "init") shift 2; djangoInit "$@" ;;
      *) echo "❌ Unknown django subcommand: $2"; show_help; exit 1 ;;
    esac
    ;;
  "--version"|"version"|"-v")
    echo "LazyCLI version $VERSION"
    ;;
  "--help"|"help")
    show_help
    ;;
  *)
    echo "❌ Unknown command: $1"
    show_help
    exit 1
    ;;
esac