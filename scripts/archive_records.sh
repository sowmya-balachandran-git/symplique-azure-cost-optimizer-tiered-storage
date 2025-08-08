#!/usr/bin/env bash
set -euo pipefail

# Required env:
# COSMOS_ACCOUNT, COSMOS_DB, COSMOS_CONTAINER, STORAGE_ACCOUNT, ARCHIVE_CONTAINER, KEYVAULT_NAME
: "${COSMOS_ACCOUNT:?Need COSMOS_ACCOUNT}"
: "${COSMOS_DB:?Need COSMOS_DB}"
: "${COSMOS_CONTAINER:?Need COSMOS_CONTAINER}"
: "${STORAGE_ACCOUNT:?Need STORAGE_ACCOUNT}"
: "${ARCHIVE_CONTAINER:?Need ARCHIVE_CONTAINER}"
: "${KEYVAULT_NAME:?Need KEYVAULT_NAME}"
ARCHIVE_DAYS=${ARCHIVE_DAYS:-90}

az login --identity >/dev/null 2>&1 || true

COSMOS_CONNSTR=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "CosmosDBConnectionString" --query value -o tsv)
if [[ -z "$COSMOS_CONNSTR" ]]; then
  echo "Cosmos connection string missing in Key Vault"; exit 1
fi

CUTOFF_DATE=$(date -u -d "$ARCHIVE_DAYS days ago" +"%Y-%m-%dT%H:%M:%SZ")
echo "Archiving records older than $CUTOFF_DATE ..."

SQL="SELECT c.id, c.partitionKey FROM c WHERE (NOT IS_DEFINED(c.archived) OR c.archived = false) AND c.createdAt < '$CUTOFF_DATE' LIMIT 200"

CANDIDATES=$(az cosmosdb sql query --account-name "$COSMOS_ACCOUNT" --database-name "$COSMOS_DB" --container-name "$COSMOS_CONTAINER" --query "$SQL" -o json)
COUNT=$(echo "$CANDIDATES" | jq '. | length')
echo "Found $COUNT candidates."

echo "$CANDIDATES" | jq -c '.[]' | while read -r row; do
  id=$(echo "$row" | jq -r '.id')
  pk=$(echo "$row" | jq -r '.partitionKey')
  echo "Processing $id (partition=$pk)..."

  tmpdoc="/tmp/doc_${id}.json"
  az cosmosdb sql item show --account-name "$COSMOS_ACCOUNT" --database-name "$COSMOS_DB" --container-name "$COSMOS_CONTAINER" --id "$id" --partition-key "$pk" -o json > "$tmpdoc"

  payload=$(jq '.payload' "$tmpdoc")
  if [[ "$payload" == "null" ]]; then
    echo "No payload for $id; skipping"; rm -f "$tmpdoc"; continue
  fi

  printf '%s' "$payload" > "/tmp/${id}.json"
  gzip -c "/tmp/${id}.json" > "/tmp/${id}.json.gz"

  blob_name="${pk}/${id}.json.gz"
  az storage blob upload --account-name "$STORAGE_ACCOUNT" --container-name "$ARCHIVE_CONTAINER" --file "/tmp/${id}.json.gz" --name "$blob_name" --overwrite true

  blob_uri="https://${STORAGE_ACCOUNT}.blob.core.windows.net/${ARCHIVE_CONTAINER}/${blob_name}"
  modified=$(jq --arg b "$blob_uri" '.archived=true | .blobUri=$b | .archivedAt="'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"' "$tmpdoc")
  printf '%s' "$modified" > "$tmpdoc"
  az cosmosdb sql item replace --account-name "$COSMOS_ACCOUNT" --database-name "$COSMOS_DB" --container-name "$COSMOS_CONTAINER" --id "$id" --partition-key "$pk" --body @"$tmpdoc" -o none

  echo "Archived $id -> $blob_uri"
  rm -f "$tmpdoc" "/tmp/${id}.json" "/tmp/${id}.json.gz"
done

echo "Archiving done."
