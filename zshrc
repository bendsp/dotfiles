# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Auto-start tmux
if [ -z "$TMUX" ] && [ -n "$PS1" ]; then
    tmux attach-session -t main || tmux new-session -s main
fi

# Set name of the theme to load
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Customize Syntax Highlighting (No green for correct commands)
ZSH_HIGHLIGHT_STYLES[command]='none'
ZSH_HIGHLIGHT_STYLES[builtin]='none'
ZSH_HIGHLIGHT_STYLES[alias]='none'
ZSH_HIGHLIGHT_STYLES[function]='none'
ZSH_HIGHLIGHT_STYLES[precommand]='none'

# Load custom dotfiles
source ~/dotfiles/aliases
source ~/dotfiles/exports
