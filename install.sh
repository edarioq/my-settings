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
  brew bundle --file "$REPO/macos/Brewfile"
elif command -v apt-get >/dev/null; then
  sudo apt-get update
  xargs sudo apt-get install -y < "$REPO/ubuntu/packages.txt"
  command -v starship >/dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y
  if ! fc-list | grep -qi "CaskaydiaCove"; then
    echo "note: install the CaskaydiaCove Nerd Font from https://www.nerdfonts.com/font-downloads"
  fi
  nvim_version="$(nvim --version | head -1 | grep -o '[0-9]*\.[0-9]*' | head -1)"
  if [ "$(printf '%s\n' "$nvim_version" 0.9 | sort -V | head -1)" != "0.9" ]; then
    echo "note: neovim $nvim_version is too old for LazyVim (needs 0.9+), install it from https://github.com/neovim/neovim/releases"
  fi
  command -v biome >/dev/null || echo "note: install Biome from https://biomejs.dev/guides/manual-installation, the Neovim config expects it on PATH"
fi

clone https://github.com/dracula/vim.git "$HOME/.vim/pack/themes/start/dracula"

link general/zsh/.zshrc             "$HOME/.zshrc"
link general/zsh/.zprofile          "$HOME/.zprofile"
# tmux reads ~/.tmux.conf as well, so the old Oh my tmux files have to go
for old in "$HOME/.tmux.conf" "$HOME/.tmux.conf.local"; do
  if [ -e "$old" ] || [ -L "$old" ]; then
    mv "$old" "$old.bak.$STAMP"
    echo "backed up $old"
  fi
done
# The whole folder, because tmux.conf looks for status.sh next to itself
link general/tmux                   "$HOME/.config/tmux"
link general/vim/.vimrc             "$HOME/.vimrc"
link general/nvim                   "$HOME/.config/nvim"
link general/git/ignore             "$HOME/.config/git/ignore"
link general/starship/starship.toml "$HOME/.config/starship.toml"
# Linked one by one because kitty keeps its own backups in that folder
link general/kitty/kitty.conf         "$HOME/.config/kitty/kitty.conf"
link general/kitty/current-theme.conf "$HOME/.config/kitty/current-theme.conf"

link general/claude/CLAUDE.md       "$HOME/.claude/CLAUDE.md"

# settings.json stays a real file because Claude Code rewrites it at runtime
if [ ! -e "$HOME/.claude/settings.json" ]; then
  mkdir -p "$HOME/.claude"
  cp "$REPO/general/claude/settings.json" "$HOME/.claude/settings.json"
  echo "copied    ~/.claude/settings.json"
fi

# ~/.gitconfig stays a real file because tools write machine-specific values into it
if ! git config --global --get-all include.path | grep -qx "$REPO/general/git/gitconfig"; then
  git config --global --add include.path "$REPO/general/git/gitconfig"
fi

case "$OS" in
  Darwin)
    link macos/borders/bordersrc        "$HOME/.config/borders/bordersrc"
    link general/ghostty/config.ghostty "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
    VSCODE="$HOME/Library/Application Support/Code/User"
    KEYS=macos
    ;;
  *)
    link general/ghostty/config.ghostty "$HOME/.config/ghostty/config"
    VSCODE="$HOME/.config/Code/User"
    # Linux uses the same ctrl/alt keys as Windows
    KEYS=windows
    ;;
esac
link general/vscode/settings.json    "$VSCODE/settings.json"
link "$KEYS/vscode/keybindings.json" "$VSCODE/keybindings.json"

if [ "$OS" != "Darwin" ] && command -v zsh >/dev/null && [ "$(basename "$SHELL")" != "zsh" ]; then
  chsh -s "$(command -v zsh)" && echo "default shell set to zsh, log out and back in"
fi

if [ ! -e "$HOME/.zshrc.local" ]; then
  echo 'export CODERABBIT_API_KEY=""' > "$HOME/.zshrc.local"
  chmod 600 "$HOME/.zshrc.local"
  echo "created   ~/.zshrc.local, put your CodeRabbit key in it"
fi
