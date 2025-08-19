#!/usr/bin/env bash
set -u

# Cores (vêm do seu setup)
source "$CONFIG_DIR/colors.sh"

CACHE_FILE="/tmp/sketchybar_weather_cache.json"
CACHE_DURATION=1800 # 30 min

curl_json() {
  # $1 = url
  curl -sS --max-time 4 --connect-timeout 2 "$1"
}

get_location() {
  # ipinfo retorna JSON com city e region
  # doc: https://ipinfo.io/developers/  (/json força JSON)
  curl_json "https://ipinfo.io/json" \
    | jq -r '(.city // "") as $c | (.region // "") as $r | {city:$c, region:$r}'
}

fetch_weather_json() {
  local city="$1"
  local region="$2"
  # wttr.in JSON: https://github.com/chubin/wttr.in (format=j1)
  # Montamos "Cidade,Regiao" e escapamos espaços com +
  local q
  q="$(printf "%s,%s" "$city" "$region" | sed 's/ /+/g')"
  curl_json "https://wttr.in/${q}?format=j1"
}

pick_icon() {
  # Descrição em minúsculas -> glifo Nerd Font (Weather Icons)
  local d="$1"

  shopt -s nocasematch
  if   [[ "$d" =~ thunder|storm|lightning ]]; then printf ""   # nf-weather-thunderstorm
  elif [[ "$d" =~ sleet|freezing\ rain ]];   then printf ""   # nf-weather-sleet
  elif [[ "$d" =~ hail ]];                   then printf "󰖒"   # nf-weather-hail
  elif [[ "$d" =~ snow|blizzard ]];          then printf ""   # nf-weather-snow
  elif [[ "$d" =~ heavy\ rain ]];            then printf ""   # nf-weather-rain_wind
  elif [[ "$d" =~ rain|drizzle|shower ]];    then printf ""   # nf-weather-rain
  elif [[ "$d" =~ fog|mist|haze|smoke ]];    then printf "󰖑"   # nf-weather-fog
  elif [[ "$d" =~ overcast|cloudy ]];        then printf "󰖐"   # nf-weather-cloudy
  elif [[ "$d" =~ partly\ cloudy|partly|broken\ clouds ]]; then printf "" # nf-weather-day_cloudy
  elif [[ "$d" =~ clear|sunny ]];            then printf "󰖨"   # nf-weather-day_sunny
  else                                           printf ""   # nf-weather-na/unknown
  fi
}

read_cache_or_update() {
  local now=$(date +%s)
  local need_update=1

  if [[ -f "$CACHE_FILE" ]]; then
    local cache_time=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
    if (( now - cache_time < CACHE_DURATION )); then
      need_update=0
    fi
  fi

  if (( need_update == 1 )); then
    local loc_json
    loc_json="$(get_location)"
    local city region
    city="$(jq -r '.city' <<<"$loc_json")"
    region="$(jq -r '.region' <<<"$loc_json")"

    # Se faltou cidade, tenta wttr.in sem local (usa geolocalização deles)
    local weather_json
    if [[ -n "$city" ]]; then
      weather_json="$(fetch_weather_json "$city" "$region")"
    else
      weather_json="$(curl_json "https://wttr.in?format=j1")"
    fi

    # Salva cache se parecer válido (tem current_condition)
    if jq -e '.current_condition[0]' >/dev/null 2>&1 <<<"$weather_json"; then
      printf "%s" "$weather_json" > "$CACHE_FILE"
    fi
  fi

  cat "$CACHE_FILE"
}

# --------- Execução ---------
weather_json="$(read_cache_or_update 2>/dev/null || true)"

if ! jq -e '.current_condition[0]' >/dev/null 2>&1 <<<"$weather_json"; then
  # Falha total: mostra placeholder
  sketchybar --set "$NAME" label="--°" icon="" icon.color="$GREY" label.color="$GREY"
  exit 0
fi

temp_c="$(jq -r '.current_condition[0].temp_C' <<<"$weather_json")"
desc="$(jq -r '.current_condition[0].weatherDesc[0].value' <<<"$weather_json")"

# Sanitiza
[[ "$temp_c" =~ ^-?[0-9]+$ ]] || temp_c="--"
[[ -n "$desc" ]] || desc="Unknown"

icon="$(pick_icon "$(tr '[:upper:]' '[:lower:]' <<<"$desc")")"
label="${temp_c}°C"

# Dica: batch de propriedades ajuda performance
# doc: https://felixkratz.github.io/SketchyBar/config/items
sketchybar --set "$NAME" \
  label="$label" \
  icon="$icon" \
  icon.color="$BLUE" \
  label.color="$WHITE"