#!/usr/bin/env bash

# Shared media helpers for media.sh / media_stream.sh / media_click.sh.
#
# Playback state comes from `media-control` (MediaRemote through a system perl),
# never from AppleScript. AppleScript sends Apple Events to Music's main thread,
# and polling it every 2s was making Music hang. media-control talks to
# mediaremoted instead, so Music is never asked anything.
# Install: see ~/projects/personal/media-control (reviewed local build).

# sketchybar is started by launchd with a bare PATH, so media-control (in
# ~/.local/bin) and jq (Homebrew) would not be found. Same fix as scripts/*.sh.
PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
export PATH

# ASCII unit separator: safe field delimiter, cannot appear in a track name.
MEDIA_DELIM=$'\x1f'

# Succeeds when bundle id $1 is one of the players the widget is allowed to show.
media_bundle_allowed() {
  case " ${MEDIA_BUNDLES:-com.apple.Music com.spotify.client} " in
    *" $1 "*) return 0 ;;
  esac
  return 1
}

# Writes the current track's cover art to $1. Returns non-zero when there is no
# art (yet): MediaRemote often publishes the title before the artwork.
media_extract_art() {
  local out="$1"
  media-control get 2> /dev/null | jq -r '.artworkData // empty' | base64 -D > "$out" 2> /dev/null
  [ -s "$out" ]
}
