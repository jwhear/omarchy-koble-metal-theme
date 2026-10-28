#!/usr/bin/env bash
# Removes everything extras/install.sh added and restores the stock
# workspaces widget in the same place.
set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy"
SHELL_JSON="$CONFIG/shell.json"
HOOK="$CONFIG/hooks/theme-set.d/koble-metal"
TOGGLE="$HOME/.local/state/omarchy/toggles/hypr/koble-metal.lua"

in_bar() {
  [[ -f $SHELL_JSON ]] && jq -e --arg id "$1" '
    [.bar.layout // {} | .[]?[]? | .id] | index($id)
  ' "$SHELL_JSON" >/dev/null
}

if in_bar koble.workspaces; then
  in_bar omarchy.workspaces || omarchy plugin enable omarchy.workspaces --after koble.workspaces
  omarchy plugin disable koble.workspaces
fi
omarchy plugin disable koble.bar-glow 2>/dev/null || true

rm -rf -- "$CONFIG/plugins/koble.bar-glow" "$CONFIG/plugins/koble.workspaces"
omarchy-shell shell rescanPlugins >/dev/null

rm -f -- "$HOOK"
if [[ -f $TOGGLE ]]; then
  rm -f -- "$TOGGLE"
  hyprctl reload >/dev/null
fi

echo "Koble Metal extras removed."
