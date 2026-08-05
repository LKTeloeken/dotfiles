#!/usr/bin/env bash

sketchybar --add item front_app left \
           --set front_app icon.font="$FONT_FRONT_APP_ICON" \
                           icon.color="$DEFAULT_ICON_COLOR" \
                           label.color="$CONTENT_LABEL_COLOR" \
                           background.color="$FRONT_APP_BACKGROUND_COLOR" \
                           background.border_width=$ITEM_BG_BORDER_WIDTH \
                           script="$PLUGIN_DIR/front_app.sh" \
           --subscribe front_app front_app_switched
