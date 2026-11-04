#!/usr/bin/env bash
#
# Cycles through windows in fullscreen (Alt+Shift+S in rift/config.toml):
# takes the current window out of fullscreen, focuses the next one and puts it
# in fullscreen.
#
# rift only has a toggle, so a fixed toggle/next/toggle chain flips whatever
# state each window is in. This checks the state first instead, like
# aerospace's explicit `fullscreen off` / `fullscreen on`.

set -eu
export PATH="/opt/homebrew/bin:$PATH"

# Whether the selected window is in fullscreen within gaps
selected_is_fullscreen() {
  rift-cli query layout |
    jq -e '[.. | objects | select(.node_type == "window" and .is_selected)][0].is_fullscreen_within_gaps' >/dev/null
}

if selected_is_fullscreen; then
  rift-cli execute window toggle-fullscreen-within-gaps >/dev/null
fi
rift-cli execute window next >/dev/null
if ! selected_is_fullscreen; then
  rift-cli execute window toggle-fullscreen-within-gaps >/dev/null
fi
