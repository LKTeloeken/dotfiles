#!/usr/bin/env bash

source "$CONFIG_DIR/styles.sh"

# The trigger in ~/.aerospace.toml already hands us the focused workspace;
# only shell out when it is missing (routine updates, front_app_switched).
FOCUSED="${AEROSPACE_FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
NON_EMPTY="$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)"

args=()
for sid in $SPACE_SIDS; do
  if [ "$sid" = "$FOCUSED" ]; then
    width=$SPACE_DOT_FOCUSED_WIDTH
    color="$SPACE_DOT_COLOR_FOCUSED"
  elif printf '%s\n' "$NON_EMPTY" | grep -qx "$sid"; then
    width=$SPACE_DOT_SIZE
    color="$SPACE_DOT_COLOR_ACTIVE"
  else
    width=$SPACE_DOT_SIZE
    color="$SPACE_DOT_COLOR_EMPTY"
  fi

  args+=(--set space.$sid width=$width background.color="$color")
done

sketchybar --animate tanh 12 "${args[@]}" > /dev/null
