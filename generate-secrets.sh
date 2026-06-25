#!/usr/bin/env bash
set -euo pipefail

# Secrets generator for NixOS config
# parses secrets/secrets.nix and generates missing .age files basically

SECRETS_DIR="$(dirname "$0")/secrets"
SECRETS_NIX="$SECRETS_DIR/secrets.nix"

if [[ ! -f "$SECRETS_NIX" ]]; then
  echo "Error: $SECRETS_NIX not found"
  exit 1
fi

echo "Parsing $SECRETS_NIX"

secret_paths=$(nix eval --impure --expr "builtins.attrNames (import $SECRETS_NIX)" --json 2>/dev/null)

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to evaluate $SECRETS_NIX"
  exit 1
fi

paths=$(echo "$secret_paths" | jq -r '.[]')

# bad json
if [[ -z "$paths" ]]; then
  echo "No secrets found in $SECRETS_NIX"
  exit 0
fi

echo "Checking for missing secrets..."

missing=()
while IFS= read -r secret_path; do
  full_path="$SECRETS_DIR/$secret_path"
  
  if [[ ! -f "$full_path" ]]; then
    missing+=("$secret_path")
  fi
done <<< "$paths"

if [[ ${#missing[@]} -eq 0 ]]; then
  echo "✓ All secrets are present"
  exit 0
fi

echo "Found ${#missing[@]} missing secret(s):"
printf "  - %s\n" "${missing[@]}"
echo ""

# check agenix
if ! command -v agenix &> /dev/null; then
  echo "Error: agenix not found in PATH"
  echo "Install it or use: nix-shell -p agenix"
  exit 1
fi

cd "$SECRETS_DIR"

for secret_path in "${missing[@]}"; do
  echo "Generating $secret_path..."
  
  secret_dir="$(dirname "$secret_path")"
  mkdir -p "$secret_dir"

  # use 64 for now
  if openssl rand -hex 64 | agenix -e "$secret_path"; then
    echo "  ✓ Created"
  else
    echo "  ✗ Failed to create"
  fi
done

echo ""
echo "Done."
