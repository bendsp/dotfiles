#!/bin/bash

DOTFILES_DIR=~/dotfiles

# Function to create symlinks
link_file() {
    local src=$1
    local dest=$2

    mkdir -p "$(dirname "$dest")"

    # Back up any existing non-symlink target, including directories.
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        echo "Backing up existing $dest to ${dest}.bak"
        mv "$dest" "${dest}.bak"
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

echo "Dotfiles installation complete!"
