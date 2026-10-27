#!/usr/bin/env bash

# Event source for the Lua media widget (lua/items/media.lua).
#
# One long-lived `media-control stream` prints a JSON line whenever Now Playing
# changes; each line becomes a `media_update` event with the track in env vars.
# All the logic (filtering players, dedupe, hide grace, artwork) lives in Lua.
#
#   media_forward.sh start   (re)start the background daemon
#   media_forward.sh stop    stop it and its children
#
# `run` is the daemon body and is not meant to be called by hand.

CONFIG_DIR="${CONFIG_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
export CONFIG_DIR
source "$CONFIG_DIR/styles.sh"
source "$CONFIG_DIR/plugins/media_lib.sh"

CACHE_DIR="${MEDIA_CACHE_DIR:-/tmp/sketchybar_media}"
PID_FILE="$CACHE_DIR/forward.pid"
# How often the watcher checks that the bar is still running.
BAR_CHECK=30

# One line per event: bundle US state US title US artist US album. Newlines and
# the delimiter are scrubbed from the text so a line is always one event.
JQ_FILTER='
  .payload as $p
  | [ ($p.bundleIdentifier // ""),
      (if $p.playing then "playing" else "paused" end),
      ($p.title // ""), ($p.artist // ""), ($p.album // "") ]
  | map(tostring | gsub("[\n\r\u001f]"; " "))
  | join("\u001f")'

forward() {
  local bundle state title artist album
  while IFS="$MEDIA_DELIM" read -r bundle state title artist album; do
    sketchybar --trigger media_update \
      BUNDLE="$bundle" STATE="$state" TITLE="$title" ARTIST="$artist" ALBUM="$album" \
      < /dev/null > /dev/null 2>&1
  done
}

run() {
  trap 'pkill -P $$ 2> /dev/null' EXIT

  # The pipeline blocks on the stream, so it cannot notice the bar going away.
  # This watcher kills it then; the loop below sees the bar is gone and exits.
  (
    while pgrep -x sketchybar > /dev/null 2>&1; do sleep "$BAR_CHECK"; done
    pkill -P $$ 2> /dev/null
  ) &

  while :; do
    # --no-artwork keeps each line tiny; Lua fetches the cover on track change.
    media-control stream --no-diff --no-artwork 2> /dev/null \
      | jq --unbuffered -r "$JQ_FILTER" 2> /dev/null \
      | forward

    # stop() removes the pid file first, so a replaced daemon exits here instead
    # of restarting the stream.
    [ "$(cat "$PID_FILE" 2> /dev/null)" = "$$" ] || exit 0
    pgrep -x sketchybar > /dev/null 2>&1 || exit 0
    sleep 3
  done
}

stop() {
  local pid
  pid="$(cat "$PID_FILE" 2> /dev/null)"
  rm -f "$PID_FILE"
  [ -n "$pid" ] || return 0
  # The pid file can outlive the daemon (reboot, crash); only signal our own.
  ps -o command= -p "$pid" 2> /dev/null | grep -q "media_forward.sh" || return 0
  # Children first: the pipeline dies, then the daemon sees the pid file is gone.
  pkill -P "$pid" 2> /dev/null
  kill "$pid" 2> /dev/null
}

start() {
  stop
  mkdir -p "$CACHE_DIR"
  nohup "$CONFIG_DIR/plugins/media_forward.sh" run > /dev/null 2>&1 < /dev/null &
  echo $! > "$PID_FILE"
}

case "$1" in
  start) start ;;
  stop) stop ;;
  run) run ;;
esac
