#!/usr/bin/env bash

# Shared media helpers for media.sh / media_click.sh / media_eq.sh.
#
# Everything here goes through AppleScript on purpose. The MediaRemote path
# (sketchybar's media_change event, background.image=media.artwork and
# nowplaying-cli) is deprecated on macOS 26 and returns null in practice, so it
# cannot be used to read or to control playback.

MEDIA_APPS="Music Spotify"
# ASCII unit separator: safe field delimiter, cannot appear in a track name.
MEDIA_DELIM=$'\x1f'

# Echoes "app<US>state<US>title<US>artist<US>album" for the first running player
# that has a track loaded. State and track come back in one osascript round trip
# because this runs on the poll path, where each round trip costs ~150ms.
media_poll() {
  local app raw state
  for app in $MEDIA_APPS; do
    pgrep -x "$app" > /dev/null 2>&1 || continue

    raw="$(osascript 2> /dev/null <<EOF
set d to (ASCII character 31)
try
  tell application "$app"
    set s to player state as text
    set t to name of current track
    set a to artist of current track
    set al to album of current track
  end tell
  return s & d & t & d & a & d & al
on error
  return ""
end try
EOF
)"

    state="${raw%%"$MEDIA_DELIM"*}"
    case "$state" in
      playing | paused) printf '%s%s%s\n' "$app" "$MEDIA_DELIM" "$raw"; return 0 ;;
    esac
  done
  return 1
}

# Writes the current track's cover art to \$2. Returns non-zero when there is
# no art to extract.
media_extract_art() {
  local app="$1" out="$2" url

  if [ "$app" = "Spotify" ]; then
    # Spotify exposes a plain https URL instead of raw bytes.
    # NOTE: untested — Spotify is not installed on this machine.
    url="$(osascript -e 'tell application "Spotify" to artwork url of current track' 2>/dev/null)"
    [ -n "$url" ] || return 1
    curl -sfL --max-time 5 -o "$out" "$url" || return 1
  else
    osascript > /dev/null 2>&1 <<EOF || return 1
try
  tell application "$app"
    set d to raw data of artwork 1 of current track
  end tell
  set f to open for access POSIX file "$out" with write permission
  set eof f to 0
  write d to f
  close access f
on error
  try
    close access f
  end try
  error "no artwork"
end try
EOF
  fi

  [ -s "$out" ]
}
