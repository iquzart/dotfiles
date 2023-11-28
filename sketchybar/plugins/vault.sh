#!/bin/bash

source "$CONFIG_DIR/sensitive_vars.sh"
source "$CONFIG_DIR/colors.sh"

VAULT_ADDRESS_CHECKER=$(env | grep VAULT_ADDR | sed 's/VAULT_ADDR=//')

if [[ "$VAULT_ADDRESS_CHECKER" == "$VAULT_DEV_DOMAIN" ]]; then
    sketchybar -m --set vault \
        background.color="$GREEN" \
        label.color="$BLACK" \
        icon.color="$BLACK" \
        label="Vault Dev"
elif [[ "$VAULT_ADDRESS_CHECKER" == "$VAULT_PROD_DOMAIN" ]]; then
    sketchybar -m --set vault \
        background.color="$RED" \
        label.color="$BLACK" \
        icon.color="$BLACK" \
        label="Vault Prod"
else
    sketchybar -m --set vault \
        background.color="$GREY" \
        label.color="$BLACK" \
        icon.color="$BLACK" \
        label="No Vault"
fi
