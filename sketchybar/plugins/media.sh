#!/usr/bin/env bash

# Media widget poller.
#
# This polls because it has to: the media_change event is deprecated on macOS 26
# and never fires, so there is nothing to subscribe to. One osascript round trip
# every update_freq seconds is the whole cost; artwork is only touched when the
# track actually changes.

source "$CONFIG_DIR/styles.sh"
source "$CONFIG_DIR/plugins/media_lib.sh"

CACHE_DIR="${MEDIA_CACHE_DIR:-/tmp/sketchybar_media}"
STATE_FILE="$CACHE_DIR/state"
# Art is rendered at half scale so it stays sharp on retina.
ART_PX=$((MEDIA_ART_SIZE * 2))
POPUP_ART_PX=$((MEDIA_POPUP_ART_SIZE * 2))

MEDIA_ITEMS="media.art media.eq media.info"

hide_widget() {
  local args=()
  local item
  for item in $MEDIA_ITEMS; do
    args+=(--set "$item" drawing=off)
  done
  args+=(--set media background.drawing=off)
  args+=(--set media.art popup.drawing=off)
  sketchybar "${args[@]}" > /dev/null 2>&1
  "$CONFIG_DIR/plugins/media_eq.sh" stop
  rm -f "$STATE_FILE"
}

case "$SENDER" in
  mouse.exited.global)
    sketchybar --set media.art popup.drawing=off > /dev/null 2>&1
    exit 0
    ;;
esac

RAW="$(media_poll)" || { hide_widget; exit 0; }

IFS="$MEDIA_DELIM" read -r APP STATE TITLE ARTIST ALBUM <<< "$RAW"
[ -n "$TITLE" ] || { hide_widget; exit 0; }

mkdir -p "$CACHE_DIR"

KEY="$(printf '%s|%s|%s' "$APP" "$ALBUM" "$TITLE" | md5 -q)"
ART_SM="$CACHE_DIR/${KEY}_sm.jpg"
ART_LG="$CACHE_DIR/${KEY}_lg.jpg"

PREV_KEY=""
PREV_STATE=""
if [ -f "$STATE_FILE" ]; then
  IFS='|' read -r PREV_KEY PREV_STATE < "$STATE_FILE"
fi

if [ "$KEY" != "$PREV_KEY" ] || [ ! -f "$ART_SM" ]; then
  RAW_ART="$CACHE_DIR/${KEY}_raw"
  if media_extract_art "$APP" "$RAW_ART"; then
    sips -Z "$ART_PX" "$RAW_ART" --out "$ART_SM" > /dev/null 2>&1
    sips -Z "$POPUP_ART_PX" "$RAW_ART" --out "$ART_LG" > /dev/null 2>&1
  fi
  rm -f "$RAW_ART"
  # Keep the current track fresh so a song on repeat never ages out. -c matters:
  # without it a failed extraction would leave empty files behind and the item
  # would point background.image at a broken path.
  touch -c "$ART_SM" "$ART_LG" 2> /dev/null
  "$CONFIG_DIR/plugins/media_cache.sh" maybe-prune
fi

if [ "$STATE" = "playing" ]; then
  PLAY_ICON="􀊆"
  PLAY_LABEL="Pausar"
else
  PLAY_ICON="􀊄"
  PLAY_LABEL="Tocar"
fi

args=(
  --set media background.drawing=on
  --set media.eq drawing=on
  --set media.info drawing=on label="$TITLE — $ARTIST"
  --set media.popup.title label="$TITLE"
  --set media.popup.artist label="$ARTIST — $ALBUM"
  --set media.popup.play icon="$PLAY_ICON" label="$PLAY_LABEL"
)

if [ -f "$ART_SM" ]; then
  args+=(--set media.art drawing=on icon.drawing=off background.image="$ART_SM" background.image.drawing=on)
else
  # No cover available: fall back to a note glyph in the same slot.
  args+=(--set media.art drawing=on background.image.drawing=off icon="􀑪" icon.drawing=on)
fi

if [ -f "$ART_LG" ]; then
  args+=(--set media.popup.art drawing=on background.image="$ART_LG" background.image.drawing=on)
else
  args+=(--set media.popup.art drawing=off)
fi

sketchybar "${args[@]}" > /dev/null 2>&1

# Only touch the animation loop on an actual state transition.
if [ "$STATE" != "$PREV_STATE" ]; then
  if [ "$STATE" = "playing" ]; then
    "$CONFIG_DIR/plugins/media_eq.sh" start
  else
    "$CONFIG_DIR/plugins/media_eq.sh" stop
  fi
fi

printf '%s|%s\n' "$KEY" "$STATE" > "$STATE_FILE"
