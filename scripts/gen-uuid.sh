#!/usr/bin/env bash

# Generate a UUID v4
UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null ||
  echo "$(openssl rand -hex 16 | sed 's/\(..\)/\1/g; s/\(........\)\(....\)\(....\)\(....\)\(........\)/\1-\2-\3-\4-\5/')")

echo "Generated UUID: $UUID"
