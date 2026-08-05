#!/usr/bin/env bash

# Sits directly after the spaces bracket, which covers its own members' padding,
# so front_app pays the whole gap on its side to match the spacing elsewhere.
sketchybar --add item front_app left \
           --set front_app padding_left=$ITEM_GAP \
                           icon.font="$FONT_FRONT_APP_ICON" \
                           icon.color="$DEFAULT_ICON_COLOR" \
                           label.color="$CONTENT_LABEL_COLOR" \
                           background.color="$FRONT_APP_BACKGROUND_COLOR" \
                           background.border_width=$ITEM_BG_BORDER_WIDTH \
                           script="$PLUGIN_DIR/front_app.sh" \
           --subscribe front_app front_app_switched
