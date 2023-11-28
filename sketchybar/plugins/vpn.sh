#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

IP_ADDRESS=$(scutil --nwi | grep address | sed 's/.*://' | tr -d ' ' | head -1)
IS_VPN=$(ifconfig | grep -m1 'ppp0' | awk '{ print $1 }')

if [[ $IS_VPN != "" ]]; then
	COLOR=$GREEN
	ICON=$VPN_CONNECTED
	LABEL="VPN"
else
	COLOR=$GREY
	ICON=$VPN_DISCONNECTED
	LABEL="VPN"
fi

sketchybar --set $NAME background.color=$COLOR \
	icon=$ICON \
	label="$LABEL"
