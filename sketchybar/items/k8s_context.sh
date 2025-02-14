#!/bin/bash

k8scontext=(
  script="$PLUGIN_DIR/k8s_context.sh"
  update_freq=10
  icon.color=$DARK_BLUE
  icon.padding_left=8
  icon.font="$FONT:Bold:18.0"

  label.color=$BLACK
  label.padding_right=5
  label.padding_left=5
  # background.color=$BACKGROUND_1
  background.height=26
  background.corner_radius=5
  background.padding_right=5
)

sketchybar -m --add item k8scontext right \
  --set k8scontext "${k8scontext[@]}"
