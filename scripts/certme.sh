#!/bin/bash

if [ -z "$1" ]; then
  echo "❌ Usage: $0 <domain>"
  exit 1
fi

DOMAIN="$1"
OUTPUT_DIR="./certs"
DAYS_VALID=730 # 2 years

mkdir -p "$OUTPUT_DIR"

KEY_FILE="$OUTPUT_DIR/$DOMAIN.key"
CRT_FILE="$OUTPUT_DIR/$DOMAIN.crt"

openssl req -x509 -nodes -days "$DAYS_VALID" -newkey rsa:2048 \
  -keyout "$KEY_FILE" \
  -out "$CRT_FILE" \
  -subj "/CN=$DOMAIN"

echo "Self-signed certificate generated for '$DOMAIN':"
echo "   Private Key: $KEY_FILE"
echo "   Certificate: $CRT_FILE"
