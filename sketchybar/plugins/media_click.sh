#!/usr/bin/env bash

# Playback actions for the media widget and its popup.
#
# media-control sends the command to whichever app owns "Now Playing". The
# widget refreshes itself when media_stream.sh sees the state change, so there
# is nothing to re-render here.

source "$CONFIG_DIR/styles.sh"
source "$CONFIG_DIR/plugins/media_lib.sh"

case "$1" in
  toggle)    sketchybar --set media.art popup.drawing=toggle > /dev/null 2>&1 ;;
  playpause) media-control toggle-play-pause > /dev/null 2>&1 ;;
  next)      media-control next-track > /dev/null 2>&1 ;;
  prev)      media-control previous-track > /dev/null 2>&1 ;;
esac
