#!/bin/bash

vpn=(
  script="$PLUGIN_DIR/vpn.sh"
  update_freq=30
  icon.color=$BLACK
  icon.padding_left=5
  icon.font="$FONT:Bold:16.0"
  label.color=$BLACK
  label.padding_right=5
  background.height=22
  background.corner_radius=5
  background.padding_right=5
)

sketchybar --add item vpn right \
  --set vpn "${vpn[@]}" \
  --subscribe vpn wifi_change
