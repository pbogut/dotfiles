#!/bin/env zsh
#=================================================
# name:   weather.zsh
# author: Pawel Bogut <https://pbogut.me>
# date:   22/12/2020
#=================================================
icons="$HOME/.cache/hackdeck/weather_icons"
mkdir -p "$icons"

cycle=0      #init cycle
tick=1       #tick every n secnds
refresh=900  #refresh every n seconds

city_id="$1"

show_weather() {
  json=$(curl -s 'https://pogoda.interia.pl/ajax/getWeatherHeaderData?isApp=0&cId='$city_id -H 'x-requested-with: XMLHttpRequest')
  icon_src=$(echo $json | jq -r '.icon.src')
  icon_no=$(echo $json | jq -r '.icon.number')
  temp=$(echo $json | jq -r '.temperature')
  phrase=$(echo $json | jq -r '.phrase')
  local_icon="$icons/$icon_no.png"
  if [[ ! -f $local_icon ]]; then
    curl -s "$icon_src" -o "$local_icon"
  fi
  echo '{"icon_path": "'$local_icon'", "label": "'$temp'"}'
}

show_weather

while true; do
  if [[ $cycle -ge $((refresh / tick)) ]]; then
    show_weather
    cycle=0
  fi
  cycle=$((cycle + 1))
  sleep ${tick}s
  wait
done
