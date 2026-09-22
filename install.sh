#!/usr/bin/env bash
# Links every config in this repo into place. Safe to run again.
# Anything already there is moved to <name>.bak.<timestamp> first.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"
OS="$(uname -s)"

link() {
  local src="$REPO/$1" dest="$2"
  if [ "$(readlink "$dest" 2>/dev/null)" = "$src" ]; then
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak.$STAMP"
    echo "backed up $dest"
  fi
  ln -s "$src" "$dest"
  echo "linked    $dest"
}

clone() {
  [ -d "$2" ] || git clone --depth 1 "$1" "$2"
}

if [ "$OS" = "Darwin" ] && command -v brew >/dev/null; then
  brew bundle --file "$REPO/Brewfile"
elif command -v apt-get >/dev/null; then
  sudo apt-get update
  sudo apt-get install -y zsh tmux neovim git curl build-essential ripgrep fd-find neofetch fontconfig
  command -v oh-my-posh >/dev/null || curl -s https://ohmyposh.dev/install.sh | bash -s
  if ! fc-list | grep -qi "CaskaydiaCove"; then
    echo "note: install the CaskaydiaCove Nerd Font from https://www.nerdfonts.com/font-downloads"
  fi
  nvim_version="$(nvim --version | head -1 | grep -o '[0-9]*\.[0-9]*' | head -1)"
  if [ "$(printf '%s\n' "$nvim_version" 0.9 | sort -V | head -1)" != "0.9" ]; then
    echo "note: neovim $nvim_version is too old for LazyVim (needs 0.9+), install it from https://github.com/neovim/neovim/releases"
  fi
fi

clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
clone https://github.com/dracula/vim.git "$HOME/.vim/pack/themes/start/dracula"
clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"

link zsh/.zshrc           "$HOME/.zshrc"
link zsh/.zprofile        "$HOME/.zprofile"
link tmux/.tmux.conf.local "$HOME/.tmux.conf.local"
if [ "$(readlink "$HOME/.tmux.conf" 2>/dev/null)" != "$HOME/.tmux/.tmux.conf" ]; then
  [ -e "$HOME/.tmux.conf" ] && mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak.$STAMP"
  ln -s "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
  echo "linked    $HOME/.tmux.conf"
fi
link vim/.vimrc           "$HOME/.vimrc"
link nvim                 "$HOME/.config/nvim"
link git/ignore           "$HOME/.config/git/ignore"

link claude/CLAUDE.md     "$HOME/.claude/CLAUDE.md"

# settings.json stays a real file because Claude Code rewrites it at runtime
if [ ! -e "$HOME/.claude/settings.json" ]; then
  mkdir -p "$HOME/.claude"
  cp "$REPO/claude/settings.json" "$HOME/.claude/settings.json"
  echo "copied    ~/.claude/settings.json"
fi

# ~/.gitconfig stays a real file because tools write machine-specific values into it
if ! git config --global --get-all include.path | grep -qx "$REPO/git/gitconfig"; then
  git config --global --add include.path "$REPO/git/gitconfig"
fi

case "$OS" in
  Darwin)
    link borders/bordersrc      "$HOME/.config/borders/bordersrc"
    link ghostty/config.ghostty "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
    VSCODE="$HOME/Library/Application Support/Code/User"
    KEYS=mac
    ;;
  *)
    link ghostty/config.ghostty "$HOME/.config/ghostty/config"
    VSCODE="$HOME/.config/Code/User"
    KEYS=windows
    ;;
esac
link vscode/settings.json        "$VSCODE/settings.json"
link "vscode/$KEYS/keybindings.json" "$VSCODE/keybindings.json"

if [ "$OS" != "Darwin" ] && command -v zsh >/dev/null && [ "$(basename "$SHELL")" != "zsh" ]; then
  chsh -s "$(command -v zsh)" && echo "default shell set to zsh, log out and back in"
fi

if [ ! -e "$HOME/.zshrc.local" ]; then
  echo 'export CODERABBIT_API_KEY=""' > "$HOME/.zshrc.local"
  chmod 600 "$HOME/.zshrc.local"
  echo "created   ~/.zshrc.local, put your CodeRabbit key in it"
fi
