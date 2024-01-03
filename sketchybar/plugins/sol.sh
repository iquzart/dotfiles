#!/bin/bash

# Define the URL
URL="https://api.gemini.com/v1/pricefeed"

# Use curl to fetch the data, and jq to extract the BTC price in AED
SOL_PRICE=$(curl -s "$URL" | jq -r '.[] | select(.pair == "SOLUSD") | .price')

# Check if the BTC price is not empty
if [ -n "$SOL_PRICE" ]; then
	sketchybar -m --set sol label=$SOL_PRICE
else
	sketchybar -m --set sol label=error
fi
