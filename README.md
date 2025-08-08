# Azure Billing Archiver (Terraform + Key Vault + IAM + Monitoring + Rehydrate + Cost Efficiency Logic)

This repo provisions a **cost-optimized Azure solution** that:

- Archives **old Cosmos DB billing records** (> 85 days) to **Blob Storage**.
- Stores **recent billing records** (≤ 85 days) in **Cosmos DB** for high-speed reads.
- Stores secrets in **Azure Key Vault**.
- Uses **Managed Identity + RBAC** for secure, passwordless access.
- Monitors with **Log Analytics** (90-day retention).
- Backs up **Cosmos DB** and **Blob Storage** daily.
- Removes old backups after **7 days**.
- Supports **on-demand rehydration** of archive-tier blobs.
- Implements **cost efficiency logic**:
  - Data lifecycle automatically moves from hot (Cosmos DB) → cold (Blob Storage).
  - Compression before archival (~70% smaller storage cost).
  - Deletes from Cosmos DB post-archival to reduce RU and storage usage.

> **Important:** Make `cosmos_name`, `storage_name`, and `keyvault_name` globally unique before running `terraform apply`.

---

## Quick Steps

1. Create the repo files (copy/paste from this repository).
2. `cd terraform`
3. Initialize Terraform:
   ```sh
   terraform init
   ```
4. Apply infrastructure:
   ```sh
   terraform apply -auto-approve
   ```
5. Set Cosmos DB connection string into **Azure Key Vault**  
   (see `PROJECT_DOCUMENTATION.md` for exact commands).
6. Deploy Azure Functions:
   - **archive_function/** → Moves data older than 85 days from Cosmos DB to Blob Storage.
   - **rehydrate_function/** → Restores archived data from Blob Storage to Cosmos DB.
   - Function Apps are created by Terraform — deploy via `func azure functionapp publish` or zip-deploy.
7. Provision a VM or Automation Runbook with Managed Identity to run operational scripts.

---

## New Folder Additions

- **`functions/archive_function/`** – Timer-triggered archival logic (Python)  
  `__init__.py` → Finds & moves old data  
  `function.json` → Daily CRON trigger  
  `requirements.txt` → Dependencies
- **`docs/cost_efficiency_logic.md`** – Detailed lifecycle & cost savings logic

---

## Data Flow

1. **API Layer** checks record age:
   - ≤ 85 days → Query Cosmos DB
   - > 85 days → Fetch from Blob Storage
2. **Archive Function** runs daily:
   - Queries Cosmos DB for > 85-day-old records
   - Compresses and uploads to Blob Storage
   - Deletes from Cosmos DB
3. **Rehydrate Function** (on-demand):
   - Fetches archived data from Blob
   - Restores to Cosmos DB for hot access

---
