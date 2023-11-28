#!/bin/bash

update() {
  source "$CONFIG_DIR/colors.sh"
  source "$CONFIG_DIR/icons.sh"

  INFO="$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk -F ' SSID: '  '/ SSID: / {print $2}')"
  IS_VPN=$(ifconfig | grep -m1 'ppp0' | awk '{ print $1 }')


  if [[ $IS_VPN != "" ]]; then
    COLOR=$GREEN
    ICON=$VPN_CONNECTED
    LABEL="VPN"
  elif [[ $INFO != "" ]]; then
    COLOR=$BLUE
    ICON=$WIFI_CONNECTED
    LABEL=$INFO
  else
    COLOR=$GREY
    ICON=$WIFI_DISCONNECTED
    LABEL="Not Connected"
  fi

  sketchybar --set $NAME background.color=$COLOR \
    icon=$ICON \
    label=$LABEL
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