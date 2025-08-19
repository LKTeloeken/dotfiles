#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh" # Loads all defined colors

SPACE_ICONS=("1" "2" "3" "4" "5" "6")

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
	sketchybar --animate tanh 5 --set $NAME \
		icon.color="$RED" \
		icon="${SPACE_ICONS[$1 - 1]}" 
else
	sketchybar --animate tanh 5 --set $NAME \
		icon.color="$COMMENT" \
		icon="${SPACE_ICONS[$1 - 1]}" 
fi
