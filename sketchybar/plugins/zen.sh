#!/bin/bash

zen_on() {
  sketchybar --set wifi drawing=off \
             --set apple.logo drawing=off \
             --set '/cpu.*/' drawing=off \
             --set calendar icon.drawing=off \
             --set separator drawing=off \
             --set front_app drawing=off \
             --set volume_icon drawing=off \
             --set spotify.anchor drawing=off \
             --set spotify.play updates=off \
             --set brew drawing=off \
             --set volume drawing=off \
             --set github.bell drawing=off \
             --set vpn drawing=off \
             --set k8scontext drawing=off \
             --set power drawing=off \
             --set btc drawing=off
}

zen_off() {
  sketchybar --set wifi drawing=on \
             --set apple.logo drawing=on \
             --set '/cpu.*/' drawing=on \
             --set calendar icon.drawing=on \
             --set separator drawing=on \
             --set front_app drawing=on \
             --set volume_icon drawing=on \
             --set spotify.play updates=on \
             --set brew drawing=on \
             --set volume drawing=on \
             --set github.bell drawing=on \
             --set vpn drawing=on \
             --set k8scontext drawing=on \
             --set power drawing=on \
             --set btc drawing=on 
}

if [ "$1" = "on" ]; then
  zen_on
elif [ "$1" = "off" ]; then
  zen_off
else
  if [ "$(sketchybar --query apple.logo | jq -r ".geometry.drawing")" = "on" ]; then
    zen_on
  else
    zen_off
  fi
fi

