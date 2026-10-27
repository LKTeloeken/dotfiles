#!/usr/bin/env bash

# Event source for the media widget.
#
# One long-lived `media-control stream` replaces the old 2s osascript poll: it
# prints a JSON line only when the Now Playing state changes, and this script
# turns each change into a call to media.sh. Between events nothing runs.
#
#   media_stream.sh start   (re)start the background daemon
#   media_stream.sh stop    stop it and its children
#
# `run` is the daemon body and is not meant to be called by hand.

CONFIG_DIR="${CONFIG_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
export CONFIG_DIR
source "$CONFIG_DIR/styles.sh"
source "$CONFIG_DIR/plugins/media_lib.sh"

CACHE_DIR="${MEDIA_CACHE_DIR:-/tmp/sketchybar_media}"
PID_FILE="$CACHE_DIR/stream.pid"
RENDER="$CONFIG_DIR/plugins/media.sh"

# MediaRemote briefly reports "nothing playing" between tracks. Hiding straight
# away would make the widget flicker, so an empty state must last this long.
HIDE_GRACE=2
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

# Reads events from stdin and drives media.sh. Runs inside the pipeline below.
#
# Hiding is a cancellable timer rather than `read -t`: macOS ships bash 3.2,
# whose `read -t` reports a timeout with status 1, the same as end of input.
consume() {
  local bundle state title artist album
  local shown="" hide_pid=""

  cancel_hide() {
    [ -n "$hide_pid" ] || return 0
    kill "$hide_pid" 2> /dev/null
    wait "$hide_pid" 2> /dev/null
    hide_pid=""
  }

  # </dev/null on every media.sh call: it must never read the event stream.
  while IFS="$MEDIA_DELIM" read -r bundle state title artist album; do
    if [ -z "$title" ] || ! media_bundle_allowed "$bundle"; then
      # Nothing (or something that is not music) is playing. Hide only if that
      # outlasts the grace period; a new track cancels the timer.
      if [ -n "$shown" ]; then
        shown=""
        cancel_hide
        ( sleep "$HIDE_GRACE"; "$RENDER" hide ) < /dev/null &
        hide_pid=$!
      fi
      continue
    fi

    cancel_hide
    [ "$bundle|$state|$title|$artist|$album" = "$shown" ] && continue
    shown="$bundle|$state|$title|$artist|$album"
    "$RENDER" render "$state" "$title" "$artist" "$album" "$bundle" < /dev/null
  done

  cancel_hide
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
    # --no-artwork keeps each line tiny; the cover is fetched by media.sh only
    # when the track changes.
    media-control stream --no-diff --no-artwork 2> /dev/null \
      | jq --unbuffered -r "$JQ_FILTER" 2> /dev/null \
      | consume

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
  ps -o command= -p "$pid" 2> /dev/null | grep -q "media_stream.sh" || return 0
  # Children first: the pipeline dies, then the daemon sees the pid file is gone.
  pkill -P "$pid" 2> /dev/null
  kill "$pid" 2> /dev/null
}

start() {
  stop
  mkdir -p "$CACHE_DIR"
  nohup "$CONFIG_DIR/plugins/media_stream.sh" run > /dev/null 2>&1 < /dev/null &
  echo $! > "$PID_FILE"
}

case "$1" in
  start) start ;;
  stop)
    stop
    "$RENDER" hide
    ;;
  run) run ;;
esac
