#!/usr/bin/env bash

# Right-side items are added right to left, so the visual order ends up
# [ cover ][ eq ][ title — artist ].

popup_defaults=(
  background.drawing=off
  icon.font="$FONT_SF"
  icon.color="$POPUP_ICON_COLOR"
  icon.padding_left=10
  icon.padding_right=6
  label.font="$FONT_LABEL_DEFAULT"
  label.color="$POPUP_LABEL_COLOR"
  label.padding_left=4
  label.padding_right=12
)

# --- bar items ---

sketchybar --add item media.info right \
           --set media.info drawing=off \
                            icon.drawing=off \
                            background.drawing=off \
                            label.color="$CONTENT_LABEL_COLOR" \
                            label.font="$FONT_LABEL_DEFAULT" \
                            label.max_chars=$MEDIA_LABEL_MAX_CHARS \
                            scroll_texts=on \
                            label.scroll_duration=$MEDIA_SCROLL_DURATION \
                            label.padding_left=6 \
                            label.padding_right=10 \
                            click_script="$PLUGIN_DIR/media_click.sh toggle"

sketchybar --add item media.eq right \
           --set media.eq drawing=off \
                          label.drawing=off \
                          background.drawing=off \
                          icon.font="$FONT_MONO_BOLD" \
                          icon.color="$COLOR_PRIMARY" \
                          icon.padding_left=4 \
                          icon.padding_right=2 \
                          icon="▁▁▁" \
                          click_script="$PLUGIN_DIR/media_click.sh toggle"

sketchybar --add item media.art right \
           --set media.art drawing=off \
                           updates=on \
                           update_freq=2 \
                           label.drawing=off \
                           icon.drawing=off \
                           icon.font="$FONT_SF" \
                           icon.color="$COLOR_PRIMARY" \
                           width=$((MEDIA_ART_SIZE + 8)) \
                           background.drawing=on \
                           background.color="$COLOR_TRANSPARENT" \
                           background.height=$MEDIA_ART_SIZE \
                           background.corner_radius=$MEDIA_ART_RADIUS \
                           background.image.scale=0.5 \
                           background.image.corner_radius=$MEDIA_ART_RADIUS \
                           script="$PLUGIN_DIR/media.sh" \
                           click_script="$PLUGIN_DIR/media_click.sh toggle" \
                           popup.align=center \
                           popup.horizontal=off \
                           popup.height=$POPUP_HEIGHT \
                           popup.blur_radius=$POPUP_BLUR_RADIUS \
                           popup.background.color="$POPUP_BG_COLOR" \
                           popup.background.border_color="$POPUP_BORDER_COLOR" \
                           popup.background.border_width=$POPUP_BORDER_WIDTH \
                           popup.background.corner_radius=$POPUP_CORNER_RADIUS \
           --subscribe media.art mouse.exited.global

# The pill behind the three items. Members are named explicitly so the popup
# items below are never pulled into the bracket.
sketchybar --add bracket media media.art media.eq media.info \
           --set media background.drawing=off \
                       background.color="$DEFAULT_BACKGROUND_COLOR" \
                       background.border_width=$ITEM_BG_BORDER_WIDTH \
                       background.corner_radius=$ITEM_BG_CORNER_RADIUS \
                       background.height=$ITEM_BG_HEIGHT

# --- popup ---
# Popups stack one item per row, so the transport controls are three rows
# rather than a single line of buttons.

sketchybar --add item media.popup.art popup.media.art \
           --set media.popup.art drawing=off \
                                 icon.drawing=off \
                                 label.drawing=off \
                                 background.drawing=on \
                                 background.color="$COLOR_TRANSPARENT" \
                                 width=$MEDIA_POPUP_ART_SIZE \
                                 y_offset=$(( -(MEDIA_POPUP_ART_SIZE - POPUP_HEIGHT) / 2 )) \
                                 background.height=$MEDIA_POPUP_ART_SIZE \
                                 background.image.scale=0.5 \
                                 background.image.corner_radius=8

sketchybar --add item media.popup.title popup.media.art \
           --set media.popup.title "${popup_defaults[@]}" \
                                   icon.drawing=off \
                                   label.padding_left=12 \
                                   label.max_chars=24

sketchybar --add item media.popup.artist popup.media.art \
           --set media.popup.artist "${popup_defaults[@]}" \
                                    icon.drawing=off \
                                    label.font="$FONT_LABEL_SMALL" \
                                    label.color="$POPUP_SUBLABEL_COLOR" \
                                    label.padding_left=12 \
                                    label.max_chars=28

sketchybar --add item media.popup.prev popup.media.art \
           --set media.popup.prev "${popup_defaults[@]}" \
                                  icon="􀊊" \
                                  label="Anterior" \
                                  click_script="$PLUGIN_DIR/media_click.sh prev"

sketchybar --add item media.popup.play popup.media.art \
           --set media.popup.play "${popup_defaults[@]}" \
                                  icon="􀊆" \
                                  label="Pausar" \
                                  click_script="$PLUGIN_DIR/media_click.sh playpause"

sketchybar --add item media.popup.next popup.media.art \
           --set media.popup.next "${popup_defaults[@]}" \
                                  icon="􀊌" \
                                  label="Próxima" \
                                  click_script="$PLUGIN_DIR/media_click.sh next"
