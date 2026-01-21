# Dotfiles

This repository contains my personal dotfiles and the tools I use.

## Tools & Environment

- **Terminal:** [iTerm2](https://iterm2.com/) (Minimal theme, smooth resizing)
- **Shell:** [Zsh](https://www.zsh.org/) with [Oh My Zsh](https://ohmyz.sh/)
- **Prompt:** [Starship](https://starship.rs/) (Catppuccin Mocha theme)
- **Multiplexer:** [tmux](https://github.com/tmux/tmux) (Catppuccin Mocha, Persistence via TPM)
- **Editor:** [Neovim](https://neovim.io/) (Gruvbox theme, LSP, Treesitter, Lazy.nvim)
- **Navigation:** [zoxide](https://github.com/ajeetdsouza/zoxide) (Smarter `cd`), [fzf](https://github.com/junegunn/fzf) (Fuzzy Finder)
- **Git Utilities:** [lazygit](https://github.com/jesseduffield/lazygit), [gitmux](https://github.com/arl/gitmux)
- **Modern CLI:** [eza](https://github.com/eza-community/eza) (Improved `ls`)

---

## Keybindings

### tmux (Prefix: `Option + Space`)

| Action | Binding |
| :--- | :--- |
| **Move between panes** | `Option + h/j/k/l` or `Arrows` |
| **Switch to window 1-9** | `Option + 1-9` |
| **New Window** | `Option + n` |
| **Vertical Split** | `Option + \|` |
| **Horizontal Split** | `Option + -` |
| **Zoom (Fullscreen)** | `Option + f` |
| **Kill Pane** | `Option + q` |
| **Copy Entire Pane** | `Option + a` |
| **Rename Window** | `Option + Shift + r` |
| **Reload Config** | `Prefix + r` |

### Shell Aliases & Navigation

| Command | Action |
| :--- | :--- |
| `lg` | Launch LazyGit |
| `v` / `vim` | Launch Neovim |
| `gs` | Git Status |
| `..` | Go up one directory |
| `z <dir>` | Smart jump to directory |
| `zi <dir>` | Interactive fuzzy jump |
| `Ctrl + R` | Fuzzy history search |
| `Ctrl + T` | Fuzzy file find |
| `Alt + C` | Fuzzy directory jump |

---

## Aesthetic Profile

- **Colorscheme:** Catppuccin Mocha (Terminal/tmux/Prompt) & Gruvbox (Neovim).
- **Fonts:** JetBrainsMono Nerd Font.
- **Layout:** Top-aligned status bar in tmux with rounded pill modules.

## Installation

The repository includes an `install.sh` script to manage symbolic links:

```bash
./install.sh
```
