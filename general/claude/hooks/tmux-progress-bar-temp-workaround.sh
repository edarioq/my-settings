#!/bin/sh
# TEMPORARY WORKAROUND. Delete this file, its link in install.sh and the hooks
# that call it in settings.json (repo and ~/.claude) once Claude Code shows
# Ghostty's progress bar inside tmux by itself. To check, remove the hooks,
# restart claude inside tmux and give it a task.
#
# Inside tmux, Claude Code 2.1.316 draws its screen from a process that cannot
# see it is in tmux, so it sends the progress bar without the wrapping tmux
# needs and tmux drops it. This sends the bar again, wrapped, to the tmux pane
# Claude runs in. Needs `allow-passthrough on` in tmux.conf.

case "$1" in
  start) state=3 ;;
  stop) state=0 ;;
  *) exit 0 ;;
esac

panes=$(tmux list-panes -a -F '#{pane_tty}' 2>/dev/null | tr '\n' ' ')
[ -n "$panes" ] || exit 0

# Hooks get no TMUX_PANE either, so the pane is the first ancestor process
# that runs on a tmux pane's terminal
pane_tty=$(ps -A -o pid= -o ppid= -o tty= | awk -v pid="$$" -v panes="$panes" '
  BEGIN { n = split(panes, p, " "); for (i = 1; i <= n; i++) pane[p[i]] = 1 }
  { ppid[$1] = $2; tty[$1] = "/dev/" $3 }
  END {
    while (pid > 1) {
      if (tty[pid] in pane) { print tty[pid]; exit }
      pid = ppid[pid]
    }
  }')
[ -n "$pane_tty" ] || exit 0

printf '\033Ptmux;\033\033]9;4;%s\007\033\\' "$state" > "$pane_tty"
