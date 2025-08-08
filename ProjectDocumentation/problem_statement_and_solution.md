# Problem Statement:

The current billing platform stores all historical records in Azure Cosmos DB, leading to high storage and request unit (RU) costs. Most data older than three months is rarely accessed, yet it remains in the hot data store. The system must maintain existing API contracts, ensure zero downtime, and guarantee no data loss while optimizing costs and improving data lifecycle management.

# Proposed Solution:

Adopt a tiered storage approach by keeping only recent “hot” records (≤ 3 months old) in Cosmos DB, while moving older “cold” records to Azure Blob Storage in compressed, cost-efficient formats. Maintain a lightweight metadata index in Cosmos DB for quick reference to archived records. Implement Azure Functions for automated archival and on-demand rehydration of cold data. Update the API layer with smart routing logic to transparently fetch data from either Cosmos DB or Blob Storage based on metadata. Use Terraform for infrastructure as code, enable backups for both storage layers, set up monitoring and alerts, and enforce security measures such as managed identities, RBAC, and private endpoints.

# tools used:

1. Azure Services: Cosmos DB, Blob Storage, Key Vault, Functions (Archive + Rehydrate), Monitor, Log Analytics, Backup

2. Security: Managed Identity, RBAC

3. Infrastructure: Terraform

4. Scripting: Bash, Python, Git Bash

5. Development: VS Code
