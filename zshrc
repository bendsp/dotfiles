# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# App terminals that should keep a lightweight shell instead of auto-starting tmux.
is_agent_app_terminal() {
  [ -n "${CODEX_CI:-}" ] || case "${__CFBundleIdentifier:-}" in
    com.openai.codex|com.openai.chat|com.openai.chatgpt|com.t3tools.t3code) return 0 ;;
    *) return 1 ;;
  esac
}

# Auto-start tmux (skip inside ChatGPT/Codex/T3 Code app terminals)
if [ -z "$TMUX" ] && [ -n "$PS1" ] && ! is_agent_app_terminal; then
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

# ChatGPT/Codex/T3 Code app terminal workaround:
# Cmd+J can emit Enter; ignore accidental empty submits in app terminals only.
if is_agent_app_terminal; then
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

  # App terminals: map common Cmd+Delete sequences to "delete to start of line".
  # Kept app-terminal-only so regular terminal key behavior is unchanged.
  for keymap in emacs viins; do
    bindkey -M "$keymap" '^U' backward-kill-line
    bindkey -M "$keymap" '^[[3;9~' backward-kill-line
    bindkey -M "$keymap" '^[[3;10~' backward-kill-line
    bindkey -M "$keymap" '^[[3;11~' backward-kill-line
    bindkey -M "$keymap" '^[[3;12~' backward-kill-line
    bindkey -M "$keymap" '^[[3;13~' backward-kill-line
    bindkey -M "$keymap" '^[[3;14~' backward-kill-line
    bindkey -M "$keymap" '^[[3;15~' backward-kill-line
    bindkey -M "$keymap" '^[[3;16~' backward-kill-line
    bindkey -M "$keymap" '^[[127;9u' backward-kill-line
    bindkey -M "$keymap" '^[[127;10u' backward-kill-line
    bindkey -M "$keymap" '^[[127;11u' backward-kill-line
    bindkey -M "$keymap" '^[[127;12u' backward-kill-line
    bindkey -M "$keymap" '^[[127;13u' backward-kill-line
    bindkey -M "$keymap" '^[[127;14u' backward-kill-line
    bindkey -M "$keymap" '^[[127;15u' backward-kill-line
    bindkey -M "$keymap" '^[[127;16u' backward-kill-line
  done
fi

# Initialize Starship with an app-terminal config to avoid prompt stacking.
if [ "${TERM:-}" != "dumb" ]; then
  if is_agent_app_terminal; then
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

# sentry
fpath=("/Users/ben/.local/share/zsh/site-functions" $fpath)

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<
