#!/bin/bash


source "$CONFIG_DIR/icons.sh"
source "$CONFIG_DIR/colors.sh"


CTX=$(kubectx -c)
COLOR="$([[ "$CTX" == shd* ]] && echo "$GREEN" || echo "$RED_NEO" )"



sketchybar --set $NAME label.color="$COLOR" \
icon="$KUBERNETES" \
label="$CTX" 


