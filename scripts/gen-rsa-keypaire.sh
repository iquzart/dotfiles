#!/usr/bin/env bash

set -e

# =======================
# CONFIGURATION
# =======================
KEY_NAME="rsa_key"
KEY_SIZE=4096 # 2048, 3072, 4096, etc.
OUT_DIR="./keys"
GENERATE_BASE64=true # Optional single-line Base64 public key
SHOW_CHAR_COUNT=true

# =======================
# LOGGING
# =======================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
  local level="$1"
  local color="$2"
  shift 2
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${color}[${level}]${NC} $*"
}

# =======================
# DIRECTORY HANDLING
# =======================
if [ -d "$OUT_DIR" ]; then
  TS=$(date '+%Y%m%d-%H%M%S')
  log WARN "$YELLOW" "Output directory exists. Renaming to ${OUT_DIR}.old-${TS}"
  mv "$OUT_DIR" "${OUT_DIR}.old-${TS}"
fi

mkdir -p "$OUT_DIR"

# =======================
# KEY GENERATION
# =======================
log INFO "$BLUE" "Generating RSA ${KEY_SIZE}-bit private key"
openssl genpkey \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:${KEY_SIZE} \
  -out "${OUT_DIR}/${KEY_NAME}_private.pem"

log INFO "$BLUE" "Generating public key (PEM format)"
openssl pkey \
  -in "${OUT_DIR}/${KEY_NAME}_private.pem" \
  -pubout \
  -out "${OUT_DIR}/${KEY_NAME}_public.pem"

# =======================
# OPTIONAL BASE64 PUBLIC KEY
# =======================
if [ "$GENERATE_BASE64" = true ]; then
  log INFO "$BLUE" "Generating single-line Base64 public key (no headers)"

  sed '1d;$d' "${OUT_DIR}/${KEY_NAME}_public.pem" | tr -d '\n' \
    >"${OUT_DIR}/${KEY_NAME}_public.base64"

  if [ "$SHOW_CHAR_COUNT" = true ]; then
    COUNT=$(wc -c <"${OUT_DIR}/${KEY_NAME}_public.base64")
    log INFO "$GREEN" "Base64 public key character count: ${COUNT}"
  fi
fi

# =======================
# SUMMARY
# =======================
log INFO "$GREEN" "Key generation completed successfully"
log INFO "$GREEN" "Private key : ${OUT_DIR}/${KEY_NAME}_private.pem"
log INFO "$GREEN" "Public key  : ${OUT_DIR}/${KEY_NAME}_public.pem"

if [ "$GENERATE_BASE64" = true ]; then
  log INFO "$GREEN" "Base64 pub  : ${OUT_DIR}/${KEY_NAME}_public.base64"
fi
