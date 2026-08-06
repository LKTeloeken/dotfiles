#!/usr/bin/env bash

# One dot per aerospace workspace. Spacing comes from padding rather than
# separate gap items, so the bracket below can wrap the row cleanly.
for sid in $SPACE_SIDS; do
  sketchybar --add item space.$sid left \
             --set space.$sid \
                    icon.drawing=off \
                    label.drawing=off \
                    width=$SPACE_DOT_SIZE \
                    padding_left=$SPACE_DOT_GAP \
                    padding_right=$SPACE_DOT_GAP \
                    background.drawing=on \
                    background.color="$SPACE_DOT_COLOR_EMPTY" \
                    background.border_width=0 \
                    background.height=$SPACE_DOT_SIZE \
                    background.corner_radius=$SPACE_DOT_RADIUS \
                    click_script="aerospace workspace $sid"
  
  if [ "$sid" -lt "$SPACE_LAST_INDEX" ]; then
    sketchybar --add item space_gap.$sid left \
               --set space_gap.$sid \
                      width=$SPACE_DOT_GAP \
                      padding_left=0 \
                      padding_right=0 \
                      icon.drawing=off \
                      label.drawing=off \
                      background.drawing=off
  fi
done

# The rectangle behind the dots, same fill as the front_app pill. Zero padding
# so it hugs the dot row predictably: the outermost dots already contribute
# SPACE_DOT_GAP of inner breathing room, and anything extra here eats into the
# gap that separates the bracket from front_app.
sketchybar --add bracket spaces '/space\..*/' \
           --set spaces background.drawing=on \
                        background.color="$DEFAULT_BACKGROUND_COLOR" \
                        background.border_width=$ITEM_BG_BORDER_WIDTH \
                        background.corner_radius=$ITEM_BG_CORNER_RADIUS \
                        background.height=$ITEM_BG_HEIGHT \
                        background.padding_left=0 \
                        background.padding_right=0

# Invisible driver: updates every dot in a single batch. The update_freq covers
# opening/closing windows, which aerospace does not emit an event for.
sketchybar --add item spaces_observer left \
           --set spaces_observer drawing=off \
                                 updates=on \
                                 update_freq=5 \
                                 script="$PLUGIN_DIR/aerospace.sh" \
           --subscribe spaces_observer aerospace_workspace_change front_app_switched
