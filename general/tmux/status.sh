#!/bin/sh
# Values for the tmux status bar that tmux cannot work out by itself.
# Usage: status.sh uptime | status.sh battery

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
  if command -v pmset >/dev/null 2>&1; then
    percent=$(pmset -g batt | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
  else
    for battery in /sys/class/power_supply/BAT*; do
      [ -r "$battery/capacity" ] || continue
      percent=$(cat "$battery/capacity")
      break
    done
  fi

  # Desktops and servers have no battery
  [ -n "$percent" ] || return 0

  # One Nerd Font icon per 10%, from empty to full
  awk -v percent="$percent" 'BEGIN {
    split("󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹", icon, " ")
    colour = (percent <= 20) ? "#fb4934" : (percent <= 50) ? "#fabd2f" : "#b8bb26"
    printf "#[fg=%s]%s %d%%", colour, icon[1 + int(percent / 10)], percent
  }'
}

case "$1" in
  uptime) uptime_text ;;
  battery) battery_text ;;
esac
