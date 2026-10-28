#!/usr/bin/env bash
# Optional Koble Metal extras. Run once after installing the theme:
#
#   bash ~/.config/omarchy/themes/koble-metal/extras/install.sh
#
# Installs:
#   - a theme-set hook that gives windows the Koble look (thin borders,
#     rounded corners, mint glow, frosted blur) while the theme is active
#   - koble.bar-glow: a glowing line along the bar's inner edge
#   - koble.workspaces: a glowing current-workspace block, in place of
#     omarchy.workspaces
#
# Both plugins only change anything while koble-metal is the active theme.
# Re-run after updating the theme to pick up new versions of the extras.
# extras/uninstall.sh removes everything this installs.
set -euo pipefail

EXTRAS="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy"
PLUGINS="$CONFIG/plugins"
SHELL_JSON="$CONFIG/shell.json"

for plugin in koble.bar-glow koble.workspaces; do
  mkdir -p "$PLUGINS"
  rm -rf -- "${PLUGINS:?}/$plugin"
  cp -r -- "$EXTRAS/plugins/$plugin" "$PLUGINS/$plugin"
done
omarchy-shell shell rescanPlugins >/dev/null

omarchy plugin enable koble.bar-glow

in_bar() {
  [[ -f $SHELL_JSON ]] && jq -e --arg id "$1" '
    [.bar.layout // {} | .[]?[]? | .id] | index($id)
  ' "$SHELL_JSON" >/dev/null
}

if ! in_bar koble.workspaces; then
  if in_bar omarchy.workspaces; then
    omarchy plugin enable koble.workspaces --after omarchy.workspaces
    omarchy plugin disable omarchy.workspaces
  else
    omarchy plugin enable koble.workspaces --section left
  fi
fi

omarchy hook install theme-set "$EXTRAS/hooks/koble-metal"

# Apply the window look now if the theme is already active.
theme=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)
"$CONFIG/hooks/theme-set.d/koble-metal" "$theme"

echo "Koble Metal extras installed."
