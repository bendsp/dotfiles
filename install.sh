#!/bin/bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DOTFILES_DIR="$(cd "$DOTFILES_DIR" && pwd)"

# Function to create symlinks
link_file() {
    local src=$1
    local dest=$2
    local backup="${dest}.bak"

    if [ ! -e "$src" ] && [ ! -L "$src" ]; then
        echo "Missing source: $src" >&2
        return 1
    fi

    mkdir -p "$(dirname "$dest")"

    # Back up any existing non-symlink target, including directories.
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        if [ -e "$backup" ] || [ -L "$backup" ]; then
            echo "Refusing to overwrite existing backup: $backup" >&2
            return 1
        fi

        echo "Backing up existing $dest to $backup"
        mv "$dest" "$backup"
    fi

    echo "Linking $src to $dest"
    ln -sfn "$src" "$dest"
}

# Symlink configs
link_file "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
link_file "$DOTFILES_DIR/gitmux.conf" "$HOME/.gitmux.conf"
link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
link_file "$DOTFILES_DIR/starship-codex.toml" "$HOME/.config/starship-codex.toml"
link_file "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.codex/AGENTS.md"
link_file "$DOTFILES_DIR/skills/shared" "$HOME/.agents/skills"
link_file "$DOTFILES_DIR/skills/.skill-lock.json" "$HOME/.agents/.skill-lock.json"

echo "Dotfiles installation complete!"
