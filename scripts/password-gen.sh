#!/bin/bash
#
# Generate Hex Based Password
#

# Set color
blue='\033[1;34m'
reset='\033[0m'

echo "🔐 Secure Hex Password Generator"

read -p "Enter number of bytes for password (default 16): " length
length=${length:-16}

password=$(openssl rand -hex "$length")
echo ""
echo -e "Generated Password: ${blue}${password}${reset}"

# Each byte = 8 bits = 256 possibilities = 8 bits of entropy
entropy_bits=$((length * 8))
entropy_per_char=$(bc <<<"scale=2; $entropy_bits / ${#password}")
entropy_per_byte=8

echo ""
echo "🧠 Entropy Info:"
echo "  - Bytes of randomness     : $length bytes"
echo "  - Total entropy           : $entropy_bits bits"
echo "  - Password length (hex)   : ${#password} characters"
echo "  - Entropy per character   : $entropy_per_char bits"
echo "  - Entropy per byte        : $entropy_per_byte bits (by definition)"

if [[ "$entropy_bits" -ge 128 ]]; then
  echo "  ✅ Entropy level: STRONG (suitable for most secure uses)"
elif [[ "$entropy_bits" -ge 64 ]]; then
  echo "  ⚠️  Entropy level: MODERATE (OK for short-lived secrets)"
else
  echo "  ❌ Entropy level: WEAK (avoid for critical secrets)"
fi

read -p "Copy to clipboard? (y/n): " copy_choice
if [[ "$copy_choice" == "y" || "$copy_choice" == "Y" ]]; then
  echo -n "$password" | pbcopy
  echo "📋 Password copied to clipboard!"
fi
