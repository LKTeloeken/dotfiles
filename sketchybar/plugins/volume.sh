#!/usr/bin/env bash

source "$CONFIG_DIR/styles.sh"

read_volume() {
  osascript -e 'output volume of (get volume settings)' 2> /dev/null
}

is_muted() {
  [ "$(osascript -e 'output muted of (get volume settings)' 2> /dev/null)" = "true" ]
}

# Paints the icon, the label and the slider from a percentage.
render() {
  local volume="$1" icon

  case "$volume" in
    '' | *[!0-9]*) return 0 ;;
  esac

  if is_muted || [ "$volume" -eq 0 ]; then
    icon="􀊣"
  else
    case "$volume" in
      100 | [6-9][0-9]) icon="􀊩" ;;
      [3-5][0-9])       icon="􀊧" ;;
      *)                icon="􀊥" ;;
    esac
  fi

  sketchybar --animate tanh 10 \
             --set volume icon="$icon" label="${volume}%" \
             --set volume.slider slider.percentage="$volume" > /dev/null 2>&1
}

set_volume() {
  local v="$1"
  [ "$v" -lt 0 ] && v=0
  [ "$v" -gt 100 ] && v=100
  osascript -e "set volume output volume $v" 2> /dev/null
  render "$v"
}

toggle_mute() {
  osascript -e 'set volume output muted (not output muted of (get volume settings))' 2> /dev/null
  render "$(read_volume)"
}

# click_script on the popup's mute row
if [ "$1" = "mute" ]; then
  toggle_mute
  exit 0
fi

case "$SENDER" in
  volume_change)
    render "$INFO"
    ;;
  mouse.clicked)
    if [ "$NAME" = "volume.slider" ]; then
      # The slider reports the dragged position in $PERCENTAGE.
      set_volume "$PERCENTAGE"
    elif [ "$BUTTON" = "right" ]; then
      toggle_mute
    else
      sketchybar --set volume popup.drawing=toggle > /dev/null 2>&1
    fi
    ;;
  mouse.scrolled)
    # $SCROLL_DELTA can be fractional; only its direction matters here.
    step="$(awk -v d="$SCROLL_DELTA" 'BEGIN { printf "%d", (d < 0 ? -5 : 5) }')"
    set_volume "$(($(read_volume) + step))"
    ;;
  mouse.exited.global)
    sketchybar --set volume popup.drawing=off > /dev/null 2>&1
    ;;
  *)
    # routine / forced: also covers the initial render after a --reload, which
    # the old event-only version left blank until the volume changed.
    render "$(read_volume)"
    ;;
esac
