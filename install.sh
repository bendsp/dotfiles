#!/bin/bash

DOTFILES_DIR=~/dotfiles

# Function to create symlinks
link_file() {
    local src=$1
    local dest=$2
    
    # Back up existing file if it's not a symlink
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        echo "Backing up existing $dest to ${dest}.bak"
        mv "$dest" "${dest}.bak"
    fi
    
    echo "Linking $src to $dest"
    ln -sf "$src" "$dest"
}

# Symlink configs
link_file "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"

echo "Dotfiles installation complete!"
