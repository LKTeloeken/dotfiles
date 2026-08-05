#!/usr/bin/env bash

# Album art cache housekeeping.
#
# Two rules, applied together:
#   - drop anything untouched for MEDIA_CACHE_MAX_AGE_DAYS days
#   - keep at most MEDIA_CACHE_MAX_ENTRIES tracks (2 files each: _sm and _lg)
#
# The currently playing track is touched before pruning, so a song on repeat
# never ages out.

source "$CONFIG_DIR/styles.sh"

CACHE_DIR="${MEDIA_CACHE_DIR:-/tmp/sketchybar_media}"
MAX_AGE_DAYS="${MEDIA_CACHE_MAX_AGE_DAYS:-7}"
MAX_ENTRIES="${MEDIA_CACHE_MAX_ENTRIES:-40}"
PRUNE_STAMP="$CACHE_DIR/.prune_stamp"
PRUNE_INTERVAL_MIN=60

prune() {
  [ -d "$CACHE_DIR" ] || return 0

  # Only *.jpg is ever considered, so the pid file and the stamp are safe.
  find "$CACHE_DIR" -maxdepth 1 -name '*.jpg' -mtime +"$MAX_AGE_DAYS" -delete 2>/dev/null

  local keep=$((MAX_ENTRIES * 2))
  local count
  count="$(find "$CACHE_DIR" -maxdepth 1 -name '*.jpg' | wc -l | tr -d ' ')"
  if [ "$count" -gt "$keep" ]; then
    # ls -t is newest first; everything past the cutoff is the oldest art.
    (cd "$CACHE_DIR" && ls -t ./*.jpg 2>/dev/null | tail -n +$((keep + 1)) | tr '\n' '\0' | xargs -0 rm -f 2>/dev/null)
  fi

  touch "$PRUNE_STAMP"
}

# Prunes at most once an hour. Callers hit this on every track change, which is
# already a disk-writing path, so the stamp keeps it off the 2s poll.
maybe_prune() {
  if [ -f "$PRUNE_STAMP" ] && [ -z "$(find "$PRUNE_STAMP" -mmin +$PRUNE_INTERVAL_MIN 2>/dev/null)" ]; then
    return 0
  fi
  prune
}

case "$1" in
  prune) prune ;;
  maybe-prune) maybe_prune ;;
esac
