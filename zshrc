# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Auto-start tmux (skip inside Codex app terminal)
if [ -z "$TMUX" ] && [ -n "$PS1" ] && [ -z "$CODEX_CI" ] && [ "${__CFBundleIdentifier:-}" != "com.openai.codex" ]; then
    tmux attach-session -t main || tmux new-session -s main
fi

# Set name of the theme to load
# ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Codex app terminal workaround:
# Cmd+J can emit Enter; ignore accidental empty submits in Codex only.
if [ -n "$CODEX_CI" ] || [ "${__CFBundleIdentifier:-}" = "com.openai.codex" ]; then
  codex_accept_line() {
    if [[ -z "${BUFFER//[[:space:]]/}" ]]; then
      return 0
    fi
    zle .accept-line
  }

  codex_accept_line_and_down_history() {
    if [[ -z "${BUFFER//[[:space:]]/}" ]]; then
      return 0
    fi
    zle .accept-line-and-down-history
  }

  # Override widgets directly so any mapped key path is covered.
  zle -N accept-line codex_accept_line
  zle -N accept-line-and-down-history codex_accept_line_and_down_history
fi

# Initialize Starship with a Codex-specific config to avoid prompt stacking.
if [ "${TERM:-}" != "dumb" ]; then
  if [ -n "$CODEX_CI" ] || [ "${__CFBundleIdentifier:-}" = "com.openai.codex" ]; then
    export STARSHIP_CONFIG="$HOME/.config/starship-codex.toml"
  fi
  eval "$(starship init zsh)"
fi

# Initialize Zoxide
eval "$(zoxide init zsh)"

# Customize Syntax Highlighting (No green for correct commands)
ZSH_HIGHLIGHT_STYLES[command]='none'
ZSH_HIGHLIGHT_STYLES[builtin]='none'
ZSH_HIGHLIGHT_STYLES[alias]='none'
ZSH_HIGHLIGHT_STYLES[function]='none'
ZSH_HIGHLIGHT_STYLES[precommand]='none'

# Load custom dotfiles
source ~/dotfiles/aliases
source ~/dotfiles/exports
source ~/dotfiles/fzf.zsh
