import os
import time
import logging
import gzip
import json
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobClient, BlobServiceClient

# env
BLOB_ACCOUNT_URL = os.getenv("BLOB_ACCOUNT_URL")
BLOB_CONTAINER = os.getenv("BLOB_CONTAINER", "billing-archive")
POLL_INTERVAL_SEC = int(os.getenv("POLL_INTERVAL_SEC", "30"))
MAX_POLL_MINUTES = int(os.getenv("MAX_POLL_MINUTES", "360"))  # configurable, default 6 hours

cred = DefaultAzureCredential()
blob_service = BlobServiceClient(account_url=BLOB_ACCOUNT_URL, credential=cred)

def main(req: func.HttpRequest) -> func.HttpResponse:
    blob_name = req.params.get("blob")
    if not blob_name:
        return func.HttpResponse("Missing 'blob' parameter", status_code=400)

    try:
        blob_client = blob_service.get_blob_client(container=BLOB_CONTAINER, blob=blob_name)
        props = blob_client.get_blob_properties()
        tier = getattr(props, "access_tier", None) or props.blob_tier
        archive_status = getattr(props, "archive_status", None)

        # If archive tier, request rehydrate
        if (tier and tier.lower() == "archive") or (archive_status is not None):
            logging.info(f"Blob {blob_name} is in archive. initiating rehydrate to Hot.")
            blob_client.set_standard_blob_tier("Hot")  # or "Cool"
            # Poll until rehydrate is done
            total_wait = 0
            max_wait = MAX_POLL_MINUTES * 60
            while True:
                props = blob_client.get_blob_properties()
                archive_status = getattr(props, "archive_status", None)
                # archive_status is None when rehydration is complete
                if archive_status is None:
                    break
                if total_wait >= max_wait:
                    return func.HttpResponse(f"Rehydrate in progress but timed out after {MAX_POLL_MINUTES} minutes", status_code=202)
                time.sleep(POLL_INTERVAL_SEC)
                total_wait += POLL_INTERVAL_SEC
            logging.info(f"Blob {blob_name} rehydrated successfully.")
        else:
            logging.info(f"Blob {blob_name} is in tier {tier} and ready.")

        # Now download
        stream = blob_client.download_blob()
        data = stream.readall()
        return func.HttpResponse(body=data, status_code=200, mimetype="application/octet-stream")

    except Exception as e:
        logging.error(str(e))
        return func.HttpResponse(str(e), status_code=500)
