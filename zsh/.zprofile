# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:$HOME/.docker/bin"
# End of Docker Desktop section.

[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Added by `rbenv init` on Wed Apr 29 10:16:52 EDT 2026
command -v rbenv >/dev/null && eval "$(rbenv init - --no-rehash zsh)"
