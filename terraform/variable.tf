##############################
# Project & Environment
##############################
project_name  = "symplique-cost-optimizer"
environment   = "prod"
location      = "East US"

##############################
# Cosmos DB
##############################
cosmosdb_account_name   = "sympliquecosmosdb"
cosmosdb_database_name  = "billingdb"
cosmosdb_container_name = "billingrecords"
cosmosdb_throughput     = 400

##############################
# Storage Account
##############################
storage_account_name = "sympliquestorageacct"
blob_container_name  = "billing-archive"

##############################
# Function Apps
##############################
function_app_name_archive    = "archive-billing-func"
function_app_name_rehydrate  = "rehydrate-billing-func"
function_runtime_version     = "~4"

##############################
# Key Vault
##############################
keyvault_name = "sympliquekeyvault"

##############################
# Monitoring
##############################
log_analytics_workspace_name = "sympliqueloganalytics"
alert_email                  = "alerts@symplique.com"

##############################
# Backup & Lifecycle
##############################
backup_retention_days  = 7
archive_days_threshold = 90
