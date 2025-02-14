#!/bin/bash

# Define the URL
URL="https://api.gemini.com/v1/pricefeed"

# Use curl to fetch the data, and jq to extract the FET price in AED
FET_PRICE=$(curl -s "$URL" | jq -r '.[] | select(.pair == "FETUSD") | .price' | awk '{printf "%.2f", $1 * 3.67}')
FET_LABEL="د.إ $FET_PRICE"

# Check if the fet price is not empty
if [ -n "$FET_PRICE" ]; then
  sketchybar -m --set fet label="$FET_LABEL"
else
  sketchybar -m --set fet label=error
fi
