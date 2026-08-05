#!/usr/bin/env bash

# Equalizer animation for the media widget.
#
# sketchybar's --animate only interpolates between two values of a property, so
# a looping VU meter has to be driven from outside: a small background loop
# cycles the icon through block-element frames while a track is playing.

source "$CONFIG_DIR/styles.sh"

CACHE_DIR="${MEDIA_CACHE_DIR:-/tmp/sketchybar_media}"
PID_FILE="$CACHE_DIR/eq.pid"
INTERVAL="${MEDIA_EQ_INTERVAL:-0.18}"

# Hand-picked so consecutive frames differ on every bar - a random walk reads
# as noise, this reads as a meter.
FRAMES=(
  "▁▃▂" "▂▅▄" "▄▇▅" "▆▅▇" "▇▃▆" "▅▂▄"
  "▃▄▂" "▂▆▃" "▄▇▆" "▇▄▇" "▅▂▅" "▃▁▃"
)
IDLE_FRAME="▁▁▁"

stop() {
  if [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE")" 2> /dev/null
    rm -f "$PID_FILE"
  fi
}

start() {
  # Always clear the previous loop first: after a sketchybar --reload the old
  # one is still running and would fight this one for the icon.
  stop
  mkdir -p "$CACHE_DIR"

  (
    i=0
    while :; do
      # Self-terminate if the bar goes away, so no loop outlives sketchybar.
      pgrep -x sketchybar > /dev/null 2>&1 || exit 0
      sketchybar --set media.eq icon="${FRAMES[$((i % ${#FRAMES[@]}))]}" > /dev/null 2>&1
      i=$((i + 1))
      sleep "$INTERVAL"
    done
  ) &

  echo $! > "$PID_FILE"
}

case "$1" in
  start) start ;;
  stop)
    stop
    sketchybar --set media.eq icon="$IDLE_FRAME" > /dev/null 2>&1
    ;;
esac
