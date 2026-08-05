#!/usr/bin/env bash

if [ "$SENDER" = "mouse.exited.global" ]; then
  "$CONFIG_DIR/plugins/calendar.sh" close
  exit 0
fi

sketchybar --animate tanh 10 --set "$NAME" label="$(date +'%a %d %b  -  %H:%M')"
