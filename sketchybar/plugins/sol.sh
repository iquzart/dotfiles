#!/bin/bash

# Define the URL
URL="https://api.gemini.com/v1/pricefeed"

# Use curl to fetch the data, and jq to extract the SOL price in AED
SOL_PRICE=$(curl -s "$URL" | jq -r '.[] | select(.pair == "SOLUSD") | .price' | awk '{printf "%.2f", $1 * 3.67}')
SOL_LABEL="د.إ $SOL_PRICE"

# Check if the SOL price is not empty
if [ -n "$SOL_PRICE" ]; then
	sketchybar -m --set sol label="$SOL_LABEL"
else
	sketchybar -m --set sol label=error
fi
