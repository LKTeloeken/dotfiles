#!/usr/bin/env bash

# Month grid for the date popup. Read-only, no actions.
#
# The rows are rebuilt on every open so the grid never goes stale across
# midnight or a month boundary.

source "$CONFIG_DIR/styles.sh"

MONTHS=(Janeiro Fevereiro Março Abril Maio Junho Julho
        Agosto Setembro Outubro Novembro Dezembro)
WEEKDAYS=(Domingo Segunda Terça Quarta Quinta Sexta Sábado)

row_defaults=(
  background.drawing=off
  icon.drawing=off
  label.font="$FONT_MONO"
  label.color="$POPUP_LABEL_COLOR"
  label.padding_left=12
  label.padding_right=12
)

build() {
  local args=(--remove '/date\.cal\..*/')
  local today month_idx weekday_idx header line i=0

  today="$(date +%-d)"
  month_idx="$(date +%-m)"
  weekday_idx="$(date +%w)"
  header="${WEEKDAYS[$weekday_idx]}, $today de ${MONTHS[$((month_idx - 1))]} de $(date +%Y)"

  args+=(--add item date.cal.header popup.date
         --set date.cal.header "${row_defaults[@]}"
               label="$header"
               label.font="$FONT_LABEL_DEFAULT"
               label.color="$COLOR_PRIMARY")

  # cal prints the month name, then the weekday header, then one line per week.
  while IFS= read -r line; do
    [ $i -eq 0 ] && { i=$((i + 1)); continue; }

    local name="date.cal.$i"
    local color="$POPUP_LABEL_COLOR"

    if [ $i -eq 1 ]; then
      color="$POPUP_SUBLABEL_COLOR"
    elif printf '%s\n' "$line" | awk -v d="$today" '{ for (f = 1; f <= NF; f++) if ($f == d) found = 1 } END { exit !found }'; then
      # A label carries a single color, so the whole week gets highlighted
      # rather than the one day. The exact date is spelled out in the header.
      color="$COLOR_PRIMARY"
    fi

    args+=(--add item "$name" popup.date
           --set "$name" "${row_defaults[@]}"
                 label="$line"
                 label.color="$color")
    i=$((i + 1))
  done <<< "$(cal)"

  sketchybar "${args[@]}" > /dev/null 2>&1
}

case "$1" in
  toggle)
    if [ "$(sketchybar --query date 2> /dev/null | jq -r '.popup.drawing')" = "on" ]; then
      sketchybar --set date popup.drawing=off > /dev/null 2>&1
    else
      build
      sketchybar --set date popup.drawing=on > /dev/null 2>&1
    fi
    ;;
  close)
    sketchybar --set date popup.drawing=off > /dev/null 2>&1
    ;;
esac
