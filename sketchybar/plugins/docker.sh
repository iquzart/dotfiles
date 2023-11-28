#!/bin/bash

update() {
	source "$CONFIG_DIR/icons.sh"
	source "$CONFIG_DIR/colors.sh"

	# docker ps &>/dev/null && ICON="$DOCKER_RUNNING" || ICON="$DOCKER_NOT_RUNNING"
	docker ps &>/dev/null && ICON="Containers" || ICON="Container"
	CONTAINERS_RUNNING=$(docker ps | wc -l | sed -e 's/^[ \t]*//')
	COLOR="$([ "$CONTAINERS_RUNNING" -eq 0 ] && echo "$GREY" || echo "$IBLUE")"


	sketchybar --set $NAME background.color="$COLOR" \
	icon="$ICON" \
	label="$CONTAINERS_RUNNING" 
}

click() {
  CURRENT_WIDTH="$(sketchybar --query $NAME | jq -r .label.width)"

  WIDTH=0
  if [ "$CURRENT_WIDTH" -eq "0" ]; then
    WIDTH=dynamic
  fi

  sketchybar --animate sin 20 --set $NAME label.width="$WIDTH"
}

case "$SENDER" in
  "wifi_change") update
  ;;
  "mouse.clicked") click
  ;;
esac
