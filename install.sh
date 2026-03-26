#!/bin/bash
# SRE Standards Installation Script
# Installs skills and sets up sync mechanism for developers

set -e

echo "🚀 Installing SRE Standards..."
echo ""

# Detect shell
SHELL_RC=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

# Create directories
mkdir -p ~/.claude/skills
mkdir -p ~/.sre-standards

# Clone or update repo
REPO_DIR="$HOME/.sre-standards-repo"
if [ -d "$REPO_DIR" ]; then
    echo "📦 Updating existing SRE standards..."
    cd "$REPO_DIR"
    git pull
else
    echo "📦 Cloning SRE standards repository..."
    # Replace with your actual repo URL
    git clone https://github.com/$(git config --get remote.origin.url | cut -d: -f2 | cut -d/ -f1)/sre-standards.git "$REPO_DIR" 2>/dev/null || \
    git clone https://github.com/ns-fazhar/sre-standards.git "$REPO_DIR"
fi

# Symlink skills
echo "🔗 Linking skills to ~/.claude/skills/..."
cd "$REPO_DIR/skills"
for skill in *.md; do
    if [ -f "$skill" ]; then
        ln -sf "$REPO_DIR/skills/$skill" ~/.claude/skills/"$skill"
        echo "   ✓ $skill"
    fi
done

# Add sync alias to shell config
if [ -n "$SHELL_RC" ]; then
    SYNC_ALIAS="alias sre-sync='(cd ~/.sre-standards-repo && git pull && echo \"✅ SRE standards updated to version \$(cat VERSION)\")'"

    if ! grep -q "sre-sync" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# SRE Standards sync" >> "$SHELL_RC"
        echo "$SYNC_ALIAS" >> "$SHELL_RC"
        echo "✓ Added 'sre-sync' command to $SHELL_RC"
    fi
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "📚 Available skills:"
ls -1 ~/.claude/skills/ | grep -E "^(operability|sre-)"
echo ""
echo "🔄 Update to latest: sre-sync"
echo ""
echo "💡 Usage:"
echo "   cd your-service"
echo "   claude code"
echo "   > /operability-check"
echo ""
echo "Current version: $(cat $REPO_DIR/VERSION)"
