#!/usr/bin/env zsh
# Context-Aware Configuration: Node.js Projects
# Automatically loaded when entering Node.js project directories

# Set Node.js project environment
export PROJECT_TYPE="nodejs"
export NODE_ENV="${NODE_ENV:-development}"

# Add project-specific paths
if [[ -d "$PWD/node_modules/.bin" ]]; then
    export PATH="$PWD/node_modules/.bin:$PATH"
fi

# Node.js specific aliases
alias ni="npm install"
alias nid="npm install --save-dev"
alias nr="npm run"
alias ns="npm start"
alias nt="npm test"
alias nb="npm run build"
alias nw="npm run watch"

# Package manager detection and aliases
if [[ -f "$PWD/yarn.lock" ]]; then
    alias install="yarn install"
    alias add="yarn add"
    alias remove="yarn remove"
    alias run="yarn run"
    alias start="yarn start"
    alias test="yarn test"
    alias build="yarn build"
elif [[ -f "$PWD/pnpm-lock.yaml" ]]; then
    alias install="pnpm install"
    alias add="pnpm add"
    alias remove="pnpm remove"
    alias run="pnpm run"
    alias start="pnpm start"
    alias test="pnpm test"
    alias build="pnpm build"
else
    alias install="npm install"
    alias add="npm install --save"
    alias remove="npm uninstall"
    alias run="npm run"
    alias start="npm start"
    alias test="npm test"
    alias build="npm run build"
fi

# Development server helpers
alias dev="npm run dev"
alias serve="npm run serve"

# Linting and formatting
if [[ -f "$PWD/.eslintrc.js" ]] || [[ -f "$PWD/.eslintrc.json" ]]; then
    alias lint="npm run lint"
    alias lint-fix="npm run lint:fix"
fi

if [[ -f "$PWD/.prettierrc" ]] || [[ -f "$PWD/prettier.config.js" ]]; then
    alias format="npm run format"
fi

# TypeScript support
if [[ -f "$PWD/tsconfig.json" ]]; then
    alias tsc="npx tsc"
    alias type-check="npm run type-check"
fi

echo "🟢 Node.js context loaded ($(node --version 2>/dev/null || zf::debug 'Node.js not found'))"
