#!/bin/bash

source "$CONFIG_DIR/icons.sh"

network=(
  update_freq=30
  padding_left=8
  padding_right=8
  label.width=0
  background.border_width=0
  background.corner_radius=6
  background.height=24
  icon.highlight=on
  label.highlight=on
  script="$PLUGIN_DIR/network.sh"
)

sketchybar --add item network right \
           --set network "${network[@]}" \
           --subscribe network wifi_change mouse.clicked