#!/usr/bin/env bash
#=================================================
# name:   mangohud-mode-switch
# author: Pawel Bogut <https://pbogut.me>
# date:   22/02/2022
#=================================================
config_path=$HOME/.config/MangoHud

default=$(ls $config_path/MangoHud.*.conf | head -n 1 | sed -E 's,^.*MangoHud\.([0-9]+)\..*$,\1,g')

current=$(head -n1 "$config_path/current")
link=0
echo "default:$default"
echo "current:$current"

show_hud() {
  sleep 0.2s;
  xdotool keydown Alt_L keydown b
  sleep 0.1s
  xdotool keyup b keyup Alt_L
}

if [[ $current == "" ]]; then
  cp $config_path/MangoHud.${default}.conf $config_path/MangoHud.conf
  echo ${default} > $config_path/current
  show_hud
  exit
fi

while read file; do
  id=$(ls $file | sed -E 's,^.*MangoHud\.([0-9]+)\..*$,\1,g')
  echo "id:$id"

  if [[ $link -eq 1 ]]; then
    cp $file ${config_path}/MangoHud.conf
    echo $id > ${config_path}/current
    show_hud
    exit
  fi
  if [[ $id == $current ]]; then
    link=1
    echo link=1
  fi
done <<< $(ls ${config_path}/MangoHud.*.conf; ls ${config_path}/MangoHud.*.conf)

# still on, so let go to default
cp $config_path/MangoHud.${default}.conf $config_path/MangoHud.conf
echo ${default} > $config_path/current
show_hud
