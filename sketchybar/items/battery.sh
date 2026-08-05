#!/usr/bin/env bash

sketchybar --add item battery right \
           --set battery icon.font="$FONT_SF" \
                         icon.color="$DEFAULT_ICON_COLOR" \
                         label.color="$CONTENT_LABEL_COLOR" \
                         update_freq=10 \
                         script="$PLUGIN_DIR/battery.sh" \
           --subscribe battery system_woke power_source_change
