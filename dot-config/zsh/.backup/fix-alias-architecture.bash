#!/usr/bin/env bash
set -euo pipefail

echo "=== FIXING ALIAS ARCHITECTURE ==="
echo "Moving aliases from pre-plugin to post-plugin phase for proper plugin compatibility"
echo ""

# List of aliases that should be moved from pre-plugin to post-plugin
declare -A aliases_to_move=(
    # From 30-development-integrations.zsh
    ["gh-aliases"]="ghcs='gh copilot suggest' ghce='gh copilot explain'"
    ["docker-aliases"]="dc dcu dcd dcl (Docker/Docker-compose aliases)"
    ["kubectl-aliases"]="kg='kubectl get' kd='kubectl describe' ka='kubectl apply' kdel='kubectl delete'"
    ["vscode-aliases"]="c='code .' code-insiders"
    
    # From 35-ssh-and-security.zsh  
    ["ssh-aliases"]="ssh-agent-status ssh-agent-kill ssh-keys-list ssh-keys-remove"
)

echo "🔍 Analyzing current alias placement..."

echo "Pre-plugin modules with aliases:"
echo "  - 30-development-integrations.zsh: Docker, kubectl, VS Code, GitHub Copilot aliases"
echo "  - 35-ssh-and-security.zsh: SSH management aliases"
echo "  - 25-lazy-integrations.zsh: k alias cleanup (appropriate for pre-plugin)"
echo "  - 90-warp-pre-plugin-compat.zsh: k alias cleanup (appropriate for pre-plugin)"
echo ""

echo "✅ Architecture principle validation:"
echo "  - Pre-plugin: Environment setup, safety checks, conflict prevention"
echo "  - Post-plugin: Aliases, UI customizations, user conveniences"
echo ""

echo "🎯 Recommended actions:"
echo ""
echo "1. KEEP in pre-plugin (these are conflict prevention, not user aliases):"
echo "   - k alias cleanup in 25-lazy-integrations.zsh"
echo "   - k alias cleanup in 90-warp-pre-plugin-compat.zsh"
echo ""

echo "2. MOVE to post-plugin:"
echo "   - All Docker aliases (dc, dcu, dcd, dcl)"
echo "   - All kubectl aliases (kg, kd, ka, kdel) - except k which is handled specially"
echo "   - All GitHub Copilot aliases (ghcs, ghce)" 
echo "   - All VS Code aliases (c, code-insiders)"
echo "   - All SSH management aliases (ssh-agent-*, ssh-keys-*)"
echo ""

echo "3. REASONING:"
echo "   - These are user convenience aliases, not system setup"
echo "   - They don't interfere with plugin loading"
echo "   - They should be available AFTER plugins are loaded"
echo "   - This prevents conflicts during plugin initialization"
echo ""

echo "🏗️  Implementation approach:"
echo "   1. Remove aliases from pre-plugin modules"
echo "   2. Add them to 20-comprehensive-environment.zsh (post-plugin)"
echo "   3. Organize by category (Docker, Kubernetes, etc.)"
echo "   4. Keep only essential conflict prevention in pre-plugin"
echo ""

echo "💡 With zf:: namespace and proper alias placement:"
echo "   - Our functions won't conflict (zf:: prefix)"
echo "   - Aliases won't conflict with plugin loading (post-plugin timing)"
echo "   - Remaining conflicts will be external (plugins vs terminals like Warp)"
echo "   - External conflicts are handled by compatibility modules"
echo ""

echo "🚀 This architectural approach provides:"
echo "   - Clean separation of concerns"
echo "   - Predictable initialization order"
echo "   - Minimal conflict surface area"
echo "   - Better compatibility with external tools"