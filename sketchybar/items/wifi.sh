#!/bin/bash

source "$CONFIG_DIR/icons.sh"

wifi=(
  update_freq=30 
  icon.color=$ICON_COLOR 
  icon.padding_left=8
  icon.padding_right=8
  icon.font="$FONT:Bold:16.0" 
  label.width=0
  label.color=$LABEL_COLOR
  label.padding_right=10 
  background.height=26
  background.corner_radius=5
  background.padding_right=5 
  script="$PLUGIN_DIR/wifi.sh"
)

# status_bracket=(
#   background.color=$BACKGROUND_1
#   background.border_color=$WHITE
# )

sketchybar --add item wifi right \
           --set wifi "${wifi[@]}" \
           --subscribe wifi wifi_change mouse.clicked

# sketchybar --add bracket status wifi vpn \
#            --set status "${status_bracket[@]}"
