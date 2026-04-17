#!/bin/sh

source "$CONFIG_DIR/styles.sh"

media_cover=(
  script="$PLUGIN_DIR/media.sh"
  icon.font="$FONT_ICON_DEFAULT"
  icon.color="$DEFAULT_ICON_COLOR"
  icon.padding_left=$ITEM_ICON_PADDING_LEFT
  icon.padding_right=$ITEM_ICON_PADDING_RIGHT
  label.padding_left=$ITEM_LABEL_PADDING_LEFT
  label.padding_right=$ITEM_LABEL_PADDING_RIGHT
  label.color="$CONTENT_LABEL_COLOR"
  label.font="$FONT_LABEL_DEFAULT"
  label.max_chars=30
  drawing=off
  update_freq=1
  background.color="$DEFAULT_BACKGROUND_COLOR"
  background.border_width=$ITEM_BG_BORDER_WIDTH
  background.corner_radius=$ITEM_BG_CORNER_RADIUS
  background.height=$ITEM_BG_HEIGHT
)

sketchybar --add item media.cover right \
           --set media.cover "${media_cover[@]}" \
           --subscribe media_cover media_change
