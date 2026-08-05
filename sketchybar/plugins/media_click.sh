#!/usr/bin/env bash

# Playback actions for the media widget and its popup.
#
# AppleScript rather than nowplaying-cli: the MediaRemote commands the latter
# wraps are dead on macOS 26. Both Music and Spotify accept the same verbs.

source "$CONFIG_DIR/styles.sh"
source "$CONFIG_DIR/plugins/media_lib.sh"

case "$1" in
  toggle)
    sketchybar --set media.art popup.drawing=toggle > /dev/null 2>&1
    exit 0
    ;;
esac

RAW="$(media_poll)" || exit 0
APP="${RAW%%"$MEDIA_DELIM"*}"

case "$1" in
  playpause) osascript -e "tell application \"$APP\" to playpause" > /dev/null 2>&1 ;;
  next)      osascript -e "tell application \"$APP\" to next track" > /dev/null 2>&1 ;;
  prev)      osascript -e "tell application \"$APP\" to previous track" > /dev/null 2>&1 ;;
  *)         exit 0 ;;
esac

# Reflect the change immediately instead of waiting for the next 2s poll.
"$CONFIG_DIR/plugins/media.sh"
