#!/bin/sh

source "$CONFIG_DIR/colors.sh"

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"

  case "$VOLUME" in
    [6-9][0-9]|100) 
      ICON="󰕾"
      COLOR=$ORANGE
    ;;
    [3-5][0-9]) 
      ICON="󰖀"
      COLOR=$ORANGE
    ;;
    [1-9]|[1-2][0-9]) 
      ICON="󰕿"
      COLOR=$ORANGE
    ;;
    *) 
      ICON="󰖁"
      COLOR=$RED
  esac

  sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$VOLUME%" label.color="$GREY"
fi