# tmux

Plain tmux with the key bindings and status bar of
[Oh my tmux](https://github.com/gpakosz/.tmux), without Oh my tmux itself.
Needs tmux 3.2 or newer.

| File        | What it is                                                           |
| ----------- | -------------------------------------------------------------------- |
| `tmux.conf` | The config                                                           |
| `status.sh` | Uptime and battery for the status bar. Must stay next to `tmux.conf` |

`install.sh` links this folder to `~/.config/tmux`. It moves an existing
`~/.tmux.conf` and `~/.tmux.conf.local` to backups, because tmux would load
them too.

## Try it without touching your setup

This starts a second tmux server that knows nothing about the first one. Run it
from a terminal window that is not inside tmux:

```bash
tmux -L try -f ~/Development/my-settings/general/tmux/tmux.conf
```

To stop it, run `tmux -L try kill-server`.

## What `tmux.conf` changes from plain tmux

Everything not listed here is the tmux default.

| Area      | Change                                                                       |
| --------- | ---------------------------------------------------------------------------- |
| Prefix    | `Ctrl+a` instead of `Ctrl+b`                                                 |
| Mouse     | On from the start. `prefix m` turns it off and on                            |
| Scrolling | 2 lines per wheel step instead of 5. 50000 lines of history instead of 2000  |
| Selecting | Releasing the mouse copies and stays in place. A click clears the selection  |
| Clipboard | Copies go to the system clipboard on macOS, Linux and WSL                    |
| Numbers   | Windows and panes count from 1                                               |
| Neovim    | Short Escape delay, focus events, 24-bit colour                              |
| Status bar | The Oh my tmux bar in Gruvbox Dark Hard: session, uptime, windows, battery, time, date, user, host |

## Key bindings

All after the prefix, except the last row.

| Keys                      | Action                                         |
| ------------------------- | ---------------------------------------------- |
| `-` / `_`                 | Split into top and bottom / left and right     |
| `h` `j` `k` `l`           | Move to the pane left, down, up, right         |
| `H` `J` `K` `L`           | Resize the pane                                |
| `<` / `>`                 | Swap the pane with the previous / next one     |
| `+`                       | Zoom the pane, and again to restore            |
| `Ctrl+h` / `Ctrl+l`       | Previous / next window                         |
| `Ctrl+Shift+h` / `l`      | Move the window left / right                   |
| `Tab`                     | Last window                                    |
| `Ctrl+c`                  | New session                                    |
| `Ctrl+f`                  | Find a session by name                         |
| `Shift+Tab`               | Last session                                   |
| `Enter`                   | Copy mode                                      |
| `b` / `p` / `P`           | List buffers / paste / choose a buffer to paste |
| `y`                       | Send the top buffer to the system clipboard    |
| `m`                       | Mouse off and on                               |
| `e`                       | Edit the config, then reload it                |
| `r`                       | Reload the config                              |
| `Ctrl+l` (no prefix)      | Clear the screen and the history               |

## What is gone compared to Oh my tmux

- User and host name in the bar are always the local ones. Oh my tmux showed
  the remote ones while a pane ran `ssh`
- `prefix F` (Facebook PathPicker), which was not installed
- `prefix +` moved the pane to its own window. It now uses tmux's own zoom
