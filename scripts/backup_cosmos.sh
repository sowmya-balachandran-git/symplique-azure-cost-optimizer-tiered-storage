#!/usr/bin/env bash
set -euo pipefail

# Required env:
# COSMOS_ACCOUNT, COSMOS_DB, COSMOS_CONTAINER, STORAGE_ACCOUNT, BACKUP_CONTAINER, KEYVAULT_NAME
: "${COSMOS_ACCOUNT:?Need COSMOS_ACCOUNT}"
: "${COSMOS_DB:?Need COSMOS_DB}"
: "${COSMOS_CONTAINER:?Need COSMOS_CONTAINER}"
: "${STORAGE_ACCOUNT:?Need STORAGE_ACCOUNT}"
: "${BACKUP_CONTAINER:?Need BACKUP_CONTAINER}"
: "${KEYVAULT_NAME:?Need KEYVAULT_NAME}"

az login --identity >/dev/null 2>&1 || true

COSMOS_CONNSTR=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "CosmosDBConnectionString" --query value -o tsv)
if [[ -z "$COSMOS_CONNSTR" ]]; then
  echo "Missing Cosmos connection string in Key Vault"; exit 1
fi

TS=$(date -u +"%Y%m%dT%H%M%SZ")
OUTFILE="/tmp/cosmos_backup_${TS}.json"

# Note: For large DBs use SDK with paging or change feed. This is a simple example.
az cosmosdb sql query --account-name "$COSMOS_ACCOUNT" --database-name "$COSMOS_DB" --container-name "$COSMOS_CONTAINER" --query "SELECT * FROM c" -o json > "$OUTFILE"

gzip -c "$OUTFILE" > "${OUTFILE}.gz"
BLOB_NAME="backups/${TS}.json.gz"
az storage blob upload --account-name "$STORAGE_ACCOUNT" --container-name "$BACKUP_CONTAINER" --file "${OUTFILE}.gz" --name "$BLOB_NAME" --overwrite true

echo "Uploaded backup to ${BACKUP_CONTAINER}/${BLOB_NAME}"
rm -f "$OUTFILE" "${OUTFILE}.gz"
