#!/bin/bash

source "$CONFIG_DIR/styles.sh"

FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)


# Highlight focused workspace
if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --animate tanh 10 --set "$NAME" \
    width=$SPACE_SIZE_SELECTED \
    background.drawing=on \
    background.color="$SPACE_BG_COLOR_SELECTED" \
    background.border_width=0 \
    background.height=$SPACE_SIZE_SELECTED \
    background.corner_radius=$SPACE_RADIUS_SELECTED \
    label.color="$SPACE_LABEL_COLOR_SELECTED" \
    icon.color="$SPACE_ICON_COLOR_SELECTED"
else
  sketchybar --animate tanh 10 --set "$NAME" \
    width=$SPACE_SIZE_DEFAULT \
    background.drawing=on \
    background.color="$SPACE_BG_COLOR" \
    background.border_width=0 \
    background.height=$SPACE_SIZE_DEFAULT \
    background.corner_radius=$SPACE_RADIUS_DEFAULT \
    label.color="$SPACE_LABEL_COLOR" \
    icon.color="$SPACE_ICON_COLOR"
fi
