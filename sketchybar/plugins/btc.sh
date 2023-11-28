#!/bin/bash

# Define the URL
URL="https://api.gemini.com/v1/pricefeed"

# Use curl to fetch the data, and jq to extract the BTC price in AED
BTC_PRICE=$(curl -s "$URL" | jq -r '.[] | select(.pair == "BTCUSD") | .price')

# Check if the BTC price is not empty
if [ -n "$BTC_PRICE" ]; then
    sketchybar -m --set btc label=$BTC_PRICE
else
    sketchybar -m --set btc label=error
fi
