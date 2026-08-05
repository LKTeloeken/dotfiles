#!/bin/sh

# Shared palette setup
if [ -f "$HOME/.config/colors/setup.sh" ]; then
  . "$HOME/.config/colors/setup.sh"
  COLOR_TRANSPARENT=0x00000000
  COLOR_BASE="0xff${BACKGROUND:1}"
  COLOR_MANTLE="0xff${COLOR0:1}"
  COLOR_SURFACE="0xff${COLOR8:1}"
  COLOR_PRIMARY="0xff${COLOR4:1}"
  COLOR_TEXT="0xff${FOREGROUND:1}"
  COLOR_SUBTEXT="0xff${COLOR7:1}"
  COLOR_OVERLAY="0xff${COLOR8:1}"

  # Opacity variants
  COLOR_BASE_BG="0xcc${BACKGROUND:1}"
  COLOR_SURFACE_BG="0xcc${COLOR8:1}"
  COLOR_SURFACE_SOFT="0x66${COLOR8:1}"
  COLOR_PRIMARY_BG_SOFT="0x44${COLOR4:1}"
  COLOR_PRIMARY_BG_MEDIUM="0x88${COLOR4:1}"
else
  # Fallback: Catppuccin Mocha palette
  COLOR_TRANSPARENT=0x00000000
  COLOR_BASE=0xff1e1e2e
  COLOR_MANTLE=0xff191927
  COLOR_SURFACE=0xff3f3f4d
  COLOR_PRIMARY=0xff89b4fa
  COLOR_TEXT=0xffcdd6f4
  COLOR_SUBTEXT=0xffa6adc8
  COLOR_OVERLAY=0xff585b70

  # Opacity variants
  COLOR_BASE_BG=0xcc1e1e2e
  COLOR_SURFACE_BG=0xcc3f3f4d
  COLOR_SURFACE_SOFT=0x663f3f4d
  COLOR_PRIMARY_BG_SOFT=0x4489b4fa
  COLOR_PRIMARY_BG_MEDIUM=0x8889b4fa
fi

# Shared semantic colors
DEFAULT_ICON_COLOR="$COLOR_PRIMARY"
DEFAULT_LABEL_COLOR="$COLOR_PRIMARY"
CONTENT_LABEL_COLOR="$COLOR_TEXT"
DEFAULT_BACKGROUND_COLOR="$COLOR_BASE_BG"

FRONT_APP_BACKGROUND_COLOR="$COLOR_SURFACE_BG"

# Bar style
BAR_HEIGHT=34
BAR_BLUR_RADIUS=30
BAR_Y_OFFSET=4
BAR_MARGIN=-10

# Shared typography
# SF Pro carries the SF Symbols glyphs used for date/battery/volume/media icons.
# Without setting it explicitly those glyphs only render through font fallback.
FONT_SF="SF Pro:Regular:13.0"
FONT_SF_SMALL="SF Pro:Regular:11.0"
FONT_ICON_DEFAULT="sketchybar-app-font:Regular:14.0"
FONT_LABEL_DEFAULT="Hack Nerd Font:Bold:12.0"
FONT_LABEL_SMALL="Hack Nerd Font:Regular:11.0"
FONT_FRONT_APP_ICON="sketchybar-app-font:Regular:15.0"
# Fixed width, so the calendar grid keeps its columns aligned.
FONT_MONO="Hack Nerd Font Mono:Regular:12.0"
FONT_MONO_BOLD="Hack Nerd Font Mono:Bold:12.0"

# Shared spacing and container style
ITEM_PADDING_LEFT=4
ITEM_PADDING_RIGHT=4
# Gap between the spaces bracket and front_app. Deliberately not derived from
# ITEM_PADDING: a bracket's background already covers the padding of its
# outermost member, so the neighbour has to pay the whole gap by itself, and
# raising ITEM_PADDING to compensate would push every other pill apart too.
LEFT_ITEM_GAP=18
ITEM_ICON_PADDING_LEFT=8
ITEM_ICON_PADDING_RIGHT=4
ITEM_LABEL_PADDING_LEFT=6
ITEM_LABEL_PADDING_RIGHT=8
ITEM_BG_BORDER_WIDTH=0
ITEM_BG_CORNER_RADIUS=12
ITEM_BG_HEIGHT=24

# Workspace indicator dots, grouped inside a bracket
SPACE_SIDS="1 2 3 4 5 6"
SPACE_DOT_SIZE=10
# Half of SPACE_DOT_SIZE, so an unfocused dot is a true circle.
SPACE_DOT_RADIUS=5
SPACE_DOT_FOCUSED_WIDTH=24
# Applied to both sides, so the visible gap between dots is twice this.
SPACE_DOT_GAP=7
SPACE_BRACKET_COLOR="$FRONT_APP_BACKGROUND_COLOR"
SPACE_DOT_COLOR_EMPTY="$COLOR_PRIMARY_BG_SOFT"
SPACE_DOT_COLOR_ACTIVE="$COLOR_PRIMARY_BG_MEDIUM"
SPACE_DOT_COLOR_FOCUSED="$COLOR_PRIMARY"

# Popup style
POPUP_BG_COLOR="$COLOR_BASE_BG"
POPUP_BORDER_COLOR="$COLOR_SURFACE_BG"
POPUP_BORDER_WIDTH=1
POPUP_CORNER_RADIUS=10
POPUP_HEIGHT=24
POPUP_BLUR_RADIUS=30
POPUP_LABEL_COLOR="$COLOR_TEXT"
POPUP_SUBLABEL_COLOR="$COLOR_SUBTEXT"
POPUP_ICON_COLOR="$COLOR_PRIMARY"

# Media widget
MEDIA_ART_SIZE=18
MEDIA_ART_RADIUS=4
MEDIA_POPUP_ART_SIZE=140
MEDIA_POPUP_ART_RADIUS=8
# Left indent shared by every popup row, so the cover lines up with the text.
POPUP_ROW_INDENT=12
MEDIA_LABEL_MAX_CHARS=26
MEDIA_SCROLL_DURATION=180
MEDIA_EQ_INTERVAL=0.18

# Album art cache. Lives in /tmp so macOS clears it on boot; the prune rules
# below are the safety net for long uptimes.
MEDIA_CACHE_DIR="/tmp/sketchybar_media"
MEDIA_CACHE_MAX_AGE_DAYS=7
MEDIA_CACHE_MAX_ENTRIES=40
