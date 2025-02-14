#!/bin/bash

# Define the URL
URL="https://min-api.cryptocompare.com/data/price?fsym=ADA&tsyms=AED"

# Use curl to fetch the data, and jq to extract the FET price in AED
ADA_PRICE=$(curl -s "$URL" | jq -r '.[]')
ADA_LABEL="د.إ $ADA_PRICE"

# Check if the fet price is not empty
if [ -n "$ADA_PRICE" ]; then
  sketchybar -m --set ada label="$ADA_LABEL"
else
  sketchybar -m --set ada label=error
fi
