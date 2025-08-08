#!/usr/bin/env bash
set -euo pipefail

# Required env:
# STORAGE_ACCOUNT, BACKUP_CONTAINER, DAYS_TO_KEEP (default 7)
: "${STORAGE_ACCOUNT:?Need STORAGE_ACCOUNT}"
: "${BACKUP_CONTAINER:?Need BACKUP_CONTAINER}"
DAYS_TO_KEEP=${DAYS_TO_KEEP:-7}

echo "Deleting backup blobs older than $DAYS_TO_KEEP days from $BACKUP_CONTAINER..."

CUTOFF=$(date -u -d "$DAYS_TO_KEEP days ago" +%s)

az storage blob list --account-name "$STORAGE_ACCOUNT" --container-name "$BACKUP_CONTAINER" --query "[].{name:name, properties:properties}" -o json | \
  jq -c '.[]' | while read -r b; do
    name=$(echo "$b" | jq -r '.name')
    modified=$(echo "$b" | jq -r '.properties.lastModified')
    mod_epoch=$(date -u -d "$modified" +%s)
    if (( mod_epoch < CUTOFF )); then
      echo "Deleting $name (lastModified=$modified)"
      az storage blob delete --account-name "$STORAGE_ACCOUNT" --container-name "$BACKUP_CONTAINER" --name "$name" --only-show-errors
    fi
  done

echo "Cleanup complete."
