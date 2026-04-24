#!/bin/bash
# This is created for minimal/micro containers.
awk 'NR>1 {print $4}' /proc/net/tcp | sort | uniq -c | while read count state; do
  case $state in
  01) name="ESTABLISHED" ;;
  02) name="SYN_SENT" ;;
  03) name="SYN_RECV" ;;
  04) name="FIN_WAIT1" ;;
  05) name="FIN_WAIT2" ;;
  06) name="TIME_WAIT" ;;
  07) name="CLOSE" ;;
  08) name="CLOSE_WAIT" ;;
  09) name="LAST_ACK" ;;
  0A) name="LISTEN" ;;
  0B) name="CLOSING" ;;
  *) name=$state ;;
  esac
  echo "$count $name"
done
