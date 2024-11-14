#!/bin/bash

# Define the URL
URL="https://api.gemini.com/v1/pricefeed"

# Use curl to fetch the data, and jq to extract the BTC price in AED
BTC_PRICE=$(curl -s "$URL" | jq -r '.[] | select(.pair == "BTCUSD") | .price' | awk '{printf "%.2f", $1 * 3.67}')
BTC_LABEL="د.إ $BTC_PRICE"

# Check if the BTC price is not empty
if [ -n "$BTC_PRICE" ]; then
	sketchybar -m --set btc label="$BTC_LABEL"
else
	sketchybar -m --set btc label=error
fi
