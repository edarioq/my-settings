# Shell basics that oh-my-zsh used to provide

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=10000
setopt extended_history hist_expire_dups_first hist_ignore_dups hist_ignore_space hist_verify share_history
setopt auto_cd interactive_comments

# Must run before the nvm and bun completion scripts below
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Emacs keys even if EDITOR is ever set to vim, which would switch zsh to vi mode
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
# Up/Down search history for commands starting with what is already typed
bindkey '^[[A' up-line-or-beginning-search   '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search '^[OB' down-line-or-beginning-search
bindkey '^[[3~' delete-char
bindkey '^[[H' beginning-of-line '^[[1~' beginning-of-line
bindkey '^[[F' end-of-line       '^[[4~' end-of-line
bindkey '^[[1;5C' forward-word   '^[[1;3C' forward-word
bindkey '^[[1;5D' backward-word  '^[[1;3D' backward-word
bindkey '^[[Z' reverse-menu-complete

# CLICOLOR only colors the macOS ls; the Linux one needs the flag
export CLICOLOR=1
[[ "$OSTYPE" == linux* ]] && alias ls='ls --color=auto'
alias l='ls -lah'
alias ll='ls -lh'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

command -v neofetch >/dev/null && neofetch

[ -s "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Added by Windsurf
[ -d /opt/homebrew/bin ] && export PATH="/opt/homebrew/bin:$PATH"
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Secrets and per-machine settings stay out of the repo
[ -s "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# Code reviews shortcut
gg-review() {
  local review_cmd=(cr --api-key "$CODERABBIT_API_KEY")

  local branch="${1:-$(git branch --show-current)}"

  if [ "$(git branch --show-current)" = "$branch" ]; then
    $review_cmd
    return
  fi

  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Working tree is dirty. Commit or stash before reviewing $branch."
    return 1
  fi

  git fetch origin "$branch" || return 1
  git checkout "$branch" 2>/dev/null || git checkout -b "$branch" || return 1
  git reset --hard "origin/$branch"
  $review_cmd
}

# Prompt (theme: ~/.config/starship.toml)
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v rbenv >/dev/null && eval "$(rbenv init - zsh)"

# Homebrew puts the plugins below in /opt/homebrew/share, apt in /usr/share
zsh_plugins=/opt/homebrew/share
[ -d "$zsh_plugins/zsh-autosuggestions" ] || zsh_plugins=/usr/share

# Gray suggestions from history as you type; Right arrow accepts
[ -s "$zsh_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$zsh_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
# Must be sourced last so it can wrap every key binding defined above
[ -s "$zsh_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$zsh_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
unset zsh_plugins
