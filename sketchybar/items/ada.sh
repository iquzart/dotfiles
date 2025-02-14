#!/bin/bash

ada=(
  script="$PLUGIN_DIR/ada.sh"
  update_freq=60
  icon=₳
  icon.color=$DARK_BLUE
  icon.padding_left=10
  icon.font="$FONT:Bold:16.0"
  label.color=$LABEL_COLOR
  label.padding_right=5
  label.padding_left=5
  # background.color=$BACKGROUND_1
  background.height=26
  background.corner_radius=5
  background.padding_right=5
)

sketchybar -m --add item ada right \
  --set ada "${ada[@]}"
