#!/usr/bin/env bash

sketchybar --add item date right \
           --set date icon="􀧞" \
                      icon.font="$FONT_SF" \
                      icon.color="$DEFAULT_ICON_COLOR" \
                      label.color="$CONTENT_LABEL_COLOR" \
                      update_freq=5 \
                      script="$PLUGIN_DIR/date.sh" \
                      click_script="$PLUGIN_DIR/calendar.sh toggle" \
                      popup.align=right \
                      popup.horizontal=off \
                      popup.height=$POPUP_HEIGHT \
                      popup.blur_radius=$POPUP_BLUR_RADIUS \
                      popup.background.color="$POPUP_BG_COLOR" \
                      popup.background.border_color="$POPUP_BORDER_COLOR" \
                      popup.background.border_width=$POPUP_BORDER_WIDTH \
                      popup.background.corner_radius=$POPUP_CORNER_RADIUS \
           --subscribe date mouse.exited.global
