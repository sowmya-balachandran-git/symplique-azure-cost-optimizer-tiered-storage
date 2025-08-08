#!/usr/bin/env bash
set -euo pipefail

# Usage: ./rehydrate_blob.sh <blob_name> <storage_account> <container>
BLOB_NAME=${1:-}
STORAGE_ACCOUNT=${2:-}
CONTAINER=${3:-}

if [[ -z "$BLOB_NAME" || -z "$STORAGE_ACCOUNT" || -z "$CONTAINER" ]]; then
  echo "Usage: $0 <blob_name> <storage_account> <container>"
  exit 1
fi

echo "Checking blob tier for $BLOB_NAME..."
TIER=$(az storage blob show \
  --account-name "$STORAGE_ACCOUNT" \
  --container-name "$CONTAINER" \
  --name "$BLOB_NAME" \
  --query properties.accessTier -o tsv)

echo "Access tier: $TIER"

if [[ "$TIER" == "Archive" || "$TIER" == "archive" ]]; then
  echo "Initiating rehydrate to Hot..."
  az storage blob set-tier \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name "$CONTAINER" \
    --name "$BLOB_NAME" \
    --tier Hot
  echo "Rehydration requested. It can take several hours depending on blob size."
else
  echo "No rehydration needed."
fi
