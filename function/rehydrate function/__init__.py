import os
import json
import gzip
import fzure.functions as func
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.cosmos import CosmosClient
from azure.storage.blob import BlobClient

KEYVAULT_NAME = os.getenv("KEYVAULT_NAME")
KEYVAULT_SECRET_NAME = os.getenv("KEYVAULT_SECRET_NAME", "CosmosDBConnectionString")
BLOB_ACCOUNT_URL = os.getenv("BLOB_ACCOUNT_URL")
BLOB_CONTAINER = os.getenv("BLOB_CONTAINER", "billing-archive")
COSMOS_DB = os.getenv("COSMOS_DB", "billingdb")
COSMOS_CONTAINER = os.getenv("COSMOS_CONTAINER", "billingRecords")

cred = DefaultAzureCredential()
kv_url = f"https://{KEYVAULT_NAME}.vault.azure.net"
secret_client = SecretClient(vault_url=kv_url, credential=cred)
cosmos_conn = secret_client.get_secret(KEYVAULT_SECRET_NAME).value

cosmos_client = CosmosClient.from_connection_string(cosmos_conn)
container = cosmos_client.get_database_client(COSMOS_DB).get_container_client(COSMOS_CONTAINER)

def main(req: func.HttpRequest) -> func.HttpResponse:
    rec_id = req.params.get("id")
    partition = req.params.get("partition")
    if not rec_id or not partition:
        return func.HttpResponse("Missing id or partition", status_code=400)
    try:
        doc = container.read_item(item=rec_id, partition_key=partition)
    except Exception as e:
        return func.HttpResponse(f"Cosmos read error: {str(e)}", status_code=404)

    if not doc.get("archived"):
        return func.HttpResponse(json.dumps(doc), status_code=200, mimetype="application/json")

    blob_name = f"{partition}/{rec_id}.json.gz"
    blob_client = BlobClient(account_url=BLOB_ACCOUNT_URL, container_name=BLOB_CONTAINER, blob_name=blob_name, credential=cred)
    stream = blob_client.download_blob().readall()
    decompressed = gzip.decompress(stream)
    payload = json.loads(decompressed.decode("utf-8"))
    doc["payload"] = payload
    return func.HttpResponse(json.dumps(doc), status_code=200, mimetype="application/json")
