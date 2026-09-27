#!/bin/sh
# Values for the tmux status bar that tmux cannot work out by itself.
# Usage: status.sh uptime | status.sh battery [client width]

uptime_text() {
  if [ -r /proc/uptime ]; then
    seconds=$(cut -d. -f1 /proc/uptime)
  else
    boot=$(sysctl -n kern.boottime | sed 's/.* sec = \([0-9]*\).*/\1/')
    seconds=$(($(date +%s) - boot))
  fi

  days=$((seconds / 86400))
  hours=$((seconds % 86400 / 3600))
  minutes=$((seconds % 3600 / 60))

  text="↑"
  [ "$days" -gt 0 ] && text="$text ${days}d"
  [ "$hours" -gt 0 ] && text="$text ${hours}h"
  [ "$minutes" -gt 0 ] && text="$text ${minutes}m"
  printf '%s' "$text"
}

battery_text() {
  width=${1:-80}

  if command -v pmset >/dev/null 2>&1; then
    info=$(pmset -g batt)
    percent=$(printf '%s' "$info" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
    case "$info" in
      *"Battery Power"*) arrow="↓" ;;
      *) arrow="↑" ;;
    esac
  else
    for battery in /sys/class/power_supply/BAT*; do
      [ -r "$battery/capacity" ] || continue
      percent=$(cat "$battery/capacity")
      case "$(cat "$battery/status" 2>/dev/null)" in
        Discharging) arrow="↓" ;;
        *) arrow="↑" ;;
      esac
      break
    done
  fi

  # Desktops and servers have no battery
  [ -n "$percent" ] || return 0

  if [ "$width" -ge 160 ]; then
    length=12
  elif [ "$width" -ge 130 ]; then
    length=10
  elif [ "$width" -ge 120 ]; then
    length=8
  elif [ "$width" -ge 100 ]; then
    length=6
  else
    length=4
  fi

  # Red to green. The percentage takes the colour of the last full square.
  awk -v percent="$percent" -v n="$length" -v arrow="$arrow" 'BEGIN {
    count = split("196 202 208 214 220 226 190 154 118 82 46", palette, " ")
    full = int(percent * n / 100 + 0.5)
    last = palette[1]
    printf "%s ", arrow
    for (i = 0; i < n; i++) {
      colour = (i == n - 1) ? palette[count] : palette[1 + int(i * count / n)]
      printf "#[fg=colour%s]%s", colour, (i < full) ? "◼" : "◻"
      if (i == full - 1) last = colour
    }
    printf "#[fg=colour%s] %d%%", last, percent
  }'
}

case "$1" in
  uptime) uptime_text ;;
  battery) battery_text "$2" ;;
esac
