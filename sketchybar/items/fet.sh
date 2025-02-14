#!/bin/bash

fet=(
  script="$PLUGIN_DIR/fet.sh"
  update_freq=60
  icon=fetch.ai
  icon.color=$BLUE
  icon.padding_left=10
  icon.font="$FONT:Bold:12.0"
  label.color=$LABEL_COLOR
  label.padding_right=5
  label.padding_left=5
  # background.color=$BACKGROUND_1
  background.height=26
  background.corner_radius=5
  background.padding_right=5
)

sketchybar -m --add item fet right \
  --set fet "${fet[@]}"
