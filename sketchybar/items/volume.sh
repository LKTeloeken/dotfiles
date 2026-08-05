#!/usr/bin/env bash

sketchybar --add item volume right \
           --set volume icon.font="$FONT_SF" \
                        icon.color="$DEFAULT_ICON_COLOR" \
                        label.color="$CONTENT_LABEL_COLOR" \
                        update_freq=15 \
                        script="$PLUGIN_DIR/volume.sh" \
                        popup.align=center \
                        popup.horizontal=off \
                        popup.height=$POPUP_HEIGHT \
                        popup.blur_radius=$POPUP_BLUR_RADIUS \
                        popup.background.color="$POPUP_BG_COLOR" \
                        popup.background.border_color="$POPUP_BORDER_COLOR" \
                        popup.background.border_width=$POPUP_BORDER_WIDTH \
                        popup.background.corner_radius=$POPUP_CORNER_RADIUS \
           --subscribe volume volume_change mouse.clicked mouse.scrolled mouse.exited.global

sketchybar --add slider volume.slider popup.volume 120 \
           --set volume.slider icon.drawing=off \
                               label.drawing=off \
                               background.drawing=off \
                               padding_left=10 \
                               padding_right=10 \
                               slider.background.height=6 \
                               slider.background.corner_radius=3 \
                               slider.background.color="$COLOR_SURFACE" \
                               slider.highlight_color="$COLOR_PRIMARY" \
                               slider.knob="􀀁" \
                               script="$PLUGIN_DIR/volume.sh" \
           --subscribe volume.slider mouse.clicked

sketchybar --add item volume.mute popup.volume \
           --set volume.mute background.drawing=off \
                             icon="􀊣" \
                             icon.font="$FONT_SF" \
                             icon.color="$POPUP_ICON_COLOR" \
                             icon.padding_left=10 \
                             icon.padding_right=6 \
                             label="Mudo" \
                             label.font="$FONT_LABEL_DEFAULT" \
                             label.color="$POPUP_LABEL_COLOR" \
                             label.padding_left=4 \
                             label.padding_right=12 \
                             click_script="$PLUGIN_DIR/volume.sh mute"
