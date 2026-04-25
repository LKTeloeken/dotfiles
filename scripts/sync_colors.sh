#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WAL_CACHE_DIR="$HOME/.cache/wal"
KITTY_PYWAL_FILE="$DOTFILES_DIR/kitty/pywal-colors.conf"
STARSHIP_FILE="$DOTFILES_DIR/starship.toml"

STARSHIP_FALLBACK_OVERLAY="#26233a"
STARSHIP_FALLBACK_LOVE="#eb6f92"
STARSHIP_FALLBACK_GOLD="#f6c177"
STARSHIP_FALLBACK_ROSE="#ebbcba"
STARSHIP_FALLBACK_PINE="#31748f"
STARSHIP_FALLBACK_FOAM="#9ccfd8"
STARSHIP_FALLBACK_IRIS="#c4a7e7"

write_kitty_fallback() {
  cat > "$KITTY_PYWAL_FILE" <<'EOF'
# fallback: tema atual do kitty
foreground              #cdd6f4
background              #1e1e2e
selection_foreground    #1e1e2e
selection_background    #f5e0dc
cursor                  #f5e0dc
cursor_text_color       #1e1e2e
url_color               #f5e0dc
color0 #45475a
color8 #585b70
color1 #f38ba8
color9 #f38ba8
color2 #a6e3a1
color10 #a6e3a1
color3 #f9e2af
color11 #f9e2af
color4 #89b4fa
color12 #89b4fa
color5 #f5c2e7
color13 #f5c2e7
color6 #94e2d5
color14 #94e2d5
color7 #bac2de
color15 #a6adc8
EOF
}

update_starship_palette() {
  python3 - "$STARSHIP_FILE" "$WAL_CACHE_DIR/colors.json" \
    "$STARSHIP_FALLBACK_OVERLAY" "$STARSHIP_FALLBACK_LOVE" "$STARSHIP_FALLBACK_GOLD" \
    "$STARSHIP_FALLBACK_ROSE" "$STARSHIP_FALLBACK_PINE" "$STARSHIP_FALLBACK_FOAM" "$STARSHIP_FALLBACK_IRIS" <<'PY'
import colorsys
import json
import re
import sys
from pathlib import Path

starship_path = Path(sys.argv[1])
wal_json_path = Path(sys.argv[2])
fallback = {
    "overlay": sys.argv[3],
    "love":    sys.argv[4],
    "gold":    sys.argv[5],
    "rose":    sys.argv[6],
    "pine":    sys.argv[7],
    "foam":    sys.argv[8],
    "iris":    sys.argv[9],
}

def hex_to_hsl(h):
    r, g, b = int(h[1:3], 16) / 255, int(h[3:5], 16) / 255, int(h[5:7], 16) / 255
    h_, l, s = colorsys.rgb_to_hls(r, g, b)
    return h_ * 360, s, l

def find_closest(candidates, target_hue, min_sat=0.15):
    """Find the candidate whose hue is closest to target_hue with enough saturation."""
    saturated = [(c, hex_to_hsl(c)) for c in candidates if hex_to_hsl(c)[1] >= min_sat]
    if not saturated:
        saturated = [(c, hex_to_hsl(c)) for c in candidates]

    def hue_dist(h):
        d = abs(h - target_hue)
        return min(d, 360 - d)

    return min(saturated, key=lambda x: hue_dist(x[1][0]))[0]

def find_darkest(candidates):
    return min(candidates, key=lambda c: hex_to_hsl(c)[2])

def find_lightest_desaturated(candidates, max_sat=0.35):
    soft = [(c, hex_to_hsl(c)) for c in candidates if hex_to_hsl(c)[1] <= max_sat]
    if not soft:
        soft = [(c, hex_to_hsl(c)) for c in candidates]
    return max(soft, key=lambda x: x[1][2])[0]

palette = dict(fallback)

if wal_json_path.exists():
    try:
        data = json.loads(wal_json_path.read_text())
        colors = data.get("colors", {})
        # color0 is bg-like, color7/15 are fg-like; use color1-6 + color8-14
        accent_keys = [f"color{i}" for i in list(range(1, 7)) + list(range(8, 15))]
        accents = [colors[k] for k in accent_keys if k in colors]

        if accents:
            # Semantic hue targets (degrees):
            #   love = red/pink  ~350
            #   gold = yellow    ~40
            #   rose = soft pink ~20  (desaturated warm)
            #   pine = blue-teal ~200
            #   foam = cyan      ~175
            #   iris = purple    ~280
            palette["love"] = find_closest(accents, 350, min_sat=0.25)
            palette["gold"] = find_closest(accents, 40,  min_sat=0.25)
            palette["pine"] = find_closest(accents, 200, min_sat=0.20)
            palette["foam"] = find_closest(accents, 175, min_sat=0.20)
            palette["iris"] = find_closest(accents, 280, min_sat=0.20)
            palette["rose"] = find_lightest_desaturated(accents)

            # overlay: darkest accent or use background-adjacent color8
            # overlay: derive from background, slightly lighter
            bg = data.get("special", {}).get("background", colors.get("color0", fallback["overlay"]))
            r, g, b = int(bg[1:3],16)/255, int(bg[3:5],16)/255, int(bg[5:7],16)/255
            h, l, s = colorsys.rgb_to_hls(r, g, b)
            l = min(1.0, l + 0.06)  # subtle lift above background
            s = s * 0.8  # slightly desaturate
            r2, g2, b2 = colorsys.hls_to_rgb(h, l, s)
            palette["overlay"] = f"#{int(r2*255):02x}{int(g2*255):02x}{int(b2*255):02x}"
    except Exception:
        pass

if not starship_path.exists():
    sys.exit(0)

content = starship_path.read_text()
new_block = "\n".join([
    "[palettes.rose-pine]",
    *(f"{k} = '{palette[k]}'" for k in ("overlay", "love", "gold", "rose", "pine", "foam", "iris")),
])

pattern = re.compile(r"(?ms)^\[palettes\.rose-pine\]\n.*?(?=^\[)")
if pattern.search(content):
    content = pattern.sub(new_block + "\n\n", content, count=1)
else:
    content += "\n\n" + new_block + "\n"

starship_path.write_text(content)
PY
}

# --- Kitty: enhance pywal output with proper foreground/cursor ---
write_kitty_enhanced() {
  python3 - "$WAL_CACHE_DIR/colors.json" "$KITTY_PYWAL_FILE" <<'PY'
import json, sys, colorsys
from pathlib import Path

wal = json.loads(Path(sys.argv[1]).read_text())
colors = wal.get("colors", {})
special = wal.get("special", {})

bg = special.get("background", colors.get("color0", "#1e1e2e"))
fg = special.get("foreground", colors.get("color7", "#cdd6f4"))
cursor = special.get("cursor", colors.get("color5", "#f5e0dc"))

lines = [
    "# pywal-generated (enhanced)",
    f"foreground              {fg}",
    f"background              {bg}",
    f"selection_foreground    {bg}",
    f"selection_background    {cursor}",
    f"cursor                  {cursor}",
    f"cursor_text_color       {bg}",
    f"url_color               {colors.get('color4', '#89b4fa')}",
]

# Enforce ANSI order: pywal often scrambles hues across indices.
# Reorder color1-6 by hue so terminals behave predictably:
#   slot1=red, slot2=green, slot3=yellow, slot4=blue, slot5=magenta, slot6=cyan
target_hues = [0, 120, 60, 240, 300, 180]  # ANSI standard hue targets

def hex_hue(h):
    r, g, b = int(h[1:3],16)/255, int(h[3:5],16)/255, int(h[5:7],16)/255
    return colorsys.rgb_to_hls(r, g, b)[0] * 360

def lighten(hex_color, amount=0.15):
    r, g, b = int(hex_color[1:3],16)/255, int(hex_color[3:5],16)/255, int(hex_color[5:7],16)/255
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    l = min(1.0, l + amount)
    r2, g2, b2 = colorsys.hls_to_rgb(h, l, s)
    return f"#{int(r2*255):02x}{int(g2*255):02x}{int(b2*255):02x}"

raw_accents = [colors.get(f"color{i}", "#888888") for i in range(1, 7)]
assigned = [None] * 6
used = set()

for slot_idx, target in enumerate(target_hues):
    def hue_dist(h):
        d = abs(hex_hue(h) - target)
        return min(d, 360 - d)
    candidates = [(i, hue_dist(c)) for i, c in enumerate(raw_accents) if i not in used]
    if candidates:
        best_i = min(candidates, key=lambda x: x[1])[0]
        assigned[slot_idx] = raw_accents[best_i]
        used.add(best_i)

# Fill any remaining gaps
remaining = [i for i in range(6) if i not in used]
for slot_idx in range(6):
    if assigned[slot_idx] is None:
        if remaining:
            assigned[slot_idx] = raw_accents[remaining.pop(0)]
        else:
            assigned[slot_idx] = "#888888"

# color0/color7 stay as bg-ish / fg-ish
lines.append(f"color0  {colors.get('color0', '#45475a')}")
lines.append(f"color8  {colors.get('color8', '#585b70')}")

for i, c in enumerate(assigned):
    lines.append(f"color{i+1}  {c}")
    lines.append(f"color{i+9}  {lighten(c, 0.1)}")

lines.append(f"color7  {colors.get('color7', '#bac2de')}")
lines.append(f"color15 {colors.get('color15', colors.get('color7', '#a6adc8'))}")

Path(sys.argv[2]).write_text("\n".join(lines) + "\n")
PY
}

# --- Main ---
WALLPAPER=$(osascript -e 'tell app "finder" to get posix path of (get desktop picture as alias)')

if [ -z "$WALLPAPER" ]; then
  echo "Could not find current wallpaper."
  write_kitty_fallback
  update_starship_palette
  exit 1
fi

echo "Current wallpaper: $WALLPAPER"
echo "Regenerating colors with pywal..."

WAL_CMD="$HOME/.local/bin/wal"
if [ ! -x "$WAL_CMD" ]; then
  WAL_CMD="wal"
fi

rm -rf "$WAL_CACHE_DIR"

if "$WAL_CMD" -i "$WALLPAPER" -n -q; then
  if [ -f "$WAL_CACHE_DIR/colors.json" ]; then
    write_kitty_enhanced
  elif [ -f "$WAL_CACHE_DIR/colors-kitty.conf" ]; then
    cp "$WAL_CACHE_DIR/colors-kitty.conf" "$KITTY_PYWAL_FILE"
  else
    write_kitty_fallback
  fi
else
  echo "pywal failed. Applying fallbacks."
  write_kitty_fallback
fi

update_starship_palette

echo "Reloading SketchyBar..."
sketchybar --reload

echo "Reloading JankyBorders..."
if pgrep -x "borders" >/dev/null; then
  killall borders
fi

echo "Colors synced."