#!/bin/bash

vault=(
    script="$PLUGIN_DIR/vault.sh"
    update_freq=60
    icon=􀢖
    icon.padding_left=10 
    icon.font="$FONT:Bold:16.0" 
    label.padding_right=10
    label.padding_left=5
    background.height=26
    background.corner_radius=5 
    background.padding_right=5 
)

sketchybar -m --add item vault right \
          --set vault "${vault[@]}" \
