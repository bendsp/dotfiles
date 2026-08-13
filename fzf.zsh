# Setup fzf
# ---------
if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi

# Use fd's fast, Git-aware traversal and bat previews in fzf widgets.
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers --line-range=:500 -- {}"'
export FZF_ALT_C_OPTS='--preview "eza --tree --level=2 --icons --color=always -- {}"'

source <(fzf --zsh)
