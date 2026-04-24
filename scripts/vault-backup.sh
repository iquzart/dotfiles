#!/bin/bash
#
# Create HashiCorp Vault Raft snapshot
#

if [[ -z "$VAULT_ADDR" ]]; then
  echo "❌ VAULT_ADDR is not set. Please export it before running this script."
  exit 1
fi

VAULT_HOST=$(echo "$VAULT_ADDR" | sed -E 's|https?://||')

TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")

FILENAME="${VAULT_HOST}-backup-${TIMESTAMP}.snap"

vault operator raft snapshot save "$FILENAME"
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "❌ Snapshot failed."
  exit $EXIT_CODE
fi

FULL_PATH=$(realpath "$FILENAME")
FILE_SIZE=$(du -h "$FILENAME" | cut -f1)

echo "✅ Snapshot created:"
echo "📄 File: $FULL_PATH"
echo "📦 Size: $FILE_SIZE"
