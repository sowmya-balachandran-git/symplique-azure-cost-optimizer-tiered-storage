import datetime
import logging
import os
import azure.functions as func
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient
from azure.cosmos import CosmosClient
from azure.storage.blob import BlobServiceClient

def main(mytimer: func.TimerRequest) -> None:
    utc_timestamp = datetime.datetime.utcnow().replace(tzinfo=datetime.timezone.utc)

    logging.info(f"Archive function triggered at {utc_timestamp}")

    # ---------------------------
    # 1. Connect using Managed Identity
    # ---------------------------
    credential = ManagedIdentityCredential()

    # Get secrets from Key Vault
    key_vault_url = os.environ["KEYVAULT_URL"]
    secret_client = SecretClient(vault_url=key_vault_url, credential=credential)

    cosmos_uri = secret_client.get_secret("CosmosDbUri").value
    cosmos_key = secret_client.get_secret("CosmosDbKey").value
    cosmos_db_name = os.environ["COSMOS_DB_NAME"]
    cosmos_container_name = os.environ["COSMOS_CONTAINER"]

    storage_conn_str = secret_client.get_secret("StorageAccountConnectionString").value
    blob_container_name = os.environ["BLOB_CONTAINER"]

    # ---------------------------
    # 2. Connect to Cosmos DB
    # ---------------------------
    cosmos_client = CosmosClient(cosmos_uri, credential=cosmos_key)
    database = cosmos_client.get_database_client(cosmos_db_name)
    container = database.get_container_client(cosmos_container_name)

    # ---------------------------
    # 3. Connect to Blob Storage
    # ---------------------------
    blob_service_client = BlobServiceClient.from_connection_string(storage_conn_str)
    blob_container_client = blob_service_client.get_container_client(blob_container_name)

    # ---------------------------
    # 4. Query records older than 85 days
    # ---------------------------
    cutoff_date = (datetime.datetime.utcnow() - datetime.timedelta(days=85)).isoformat()

    query = f"SELECT * FROM c WHERE c.timestamp < '{cutoff_date}'"
    old_items = list(container.query_items(query=query, enable_cross_partition_query=True))

    logging.info(f"Found {len(old_items)} items older than 85 days.")

    # ---------------------------
    # 5. Archive each record to Blob
    # ---------------------------
    for item in old_items:
        blob_name = f"{item['id']}.json"
        blob_container_client.upload_blob(
            name=blob_name,
            data=str(item),
            overwrite=True
        )

        # Delete from Cosmos DB after archiving
        container.delete_item(item=item, partition_key=item["partitionKey"])

    logging.info("Archiving complete.")
