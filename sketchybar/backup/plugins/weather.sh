#!/usr/bin/env zsh

IP=$(curl -s https://ipinfo.io/ip)
LOCATION_JSON=$(curl -s https://ipinfo.io/$IP/json)
LOCATION=$(echo $LOCATION_JSON | jq -r '.city')
REGION=$(echo $LOCATION_JSON | jq -r '.region')

LOCATION_ESCAPED="${LOCATION// /+}+${REGION// /+}"
WEATHER_JSON=$(curl -s "https://wttr.in/$LOCATION_ESCAPED?format=j1")

if [ -z "$WEATHER_JSON" ]; then
  sketchybar --set $NAME label="$LOCATION"
  sketchybar --set $NAME.moon icon=
  return
fi

TEMPERATURE=$(echo "$WEATHER_JSON" | jq -r '.current_condition[0].temp_C')
WEATHER_DESCRIPTION=$(echo "$WEATHER_JSON" | jq -r '.current_condition[0].weatherDesc[0].value' | sed 's/\(.\{25\}\).*/\1.../')
MOON_PHASE=$(echo "$WEATHER_JSON" | jq -r '.weather[0].astronomy[0].moon_phase')

# 1) parse moon phase → ICON (unchanged)
case "$MOON_PHASE" in
  "New Moon")         ICON= ;;
  "Waxing Crescent")  ICON= ;;
  "First Quarter")    ICON= ;;
  "Waxing Gibbous")   ICON= ;;
  "Full Moon")        ICON= ;;
  "Waning Gibbous")   ICON= ;;
  "Last Quarter")     ICON= ;;
  "Waning Crescent")  ICON= ;;
esac

# 2) sunrise/sunset → IS_DAY
SUNRISE=$(echo "$WEATHER_JSON" | jq -r '.weather[0].astronomy[0].sunrise')
SUNSET=$(echo   "$WEATHER_JSON" | jq -r '.weather[0].astronomy[0].sunset')
sun_to_24h() { local h m ap; read h m ap <<<$(echo $1 | awk -F'[: ]' '{print $1, $2, $3}'); (( ap=="PM" && h<12 )) && ((h+=12)); (( ap=="AM" && h==12 )) && h=0; printf "%02d" $h; }
SR_H=$(sun_to_24h "$SUNRISE")
SS_H=$(sun_to_24h "$SUNSET")
CUR_H=$(date +%H)
[ "$CUR_H" -ge "$SR_H" ] && [ "$CUR_H" -lt "$SS_H" ] && IS_DAY=true || IS_DAY=false

# 3) choose daytime icon
SUN_ICON="☀"; PARTLY_ICON="🌤"; CLOUD_ICON="☁"
if [ "$IS_DAY" = true ]; then
  case "$WEATHER_DESCRIPTION" in
    *Clear*|*Sunny*)    DAY_ICON=$SUN_ICON ;;
    *Partly*|*Few*|*Scattered*) DAY_ICON=$PARTLY_ICON ;;
    *Cloudy*|*Overcast*|*Gray*) DAY_ICON=$CLOUD_ICON ;;
    *)                  DAY_ICON=$SUN_ICON ;;
  esac
fi

# 4) final SketchyBar update
if [ "$IS_DAY" = true ]; then
  sketchybar --set $NAME        icon="$DAY_ICON" \
                       label=" $TEMPERATURE℃ $WEATHER_DESCRIPTION"
  sketchybar --set $NAME.moon drawing=off
else
  sketchybar --set $NAME        icon="" \
                       label=" $TEMPERATURE℃ $WEATHER_DESCRIPTION"
  sketchybar --set $NAME.moon   drawing=on icon="$ICON"
fi