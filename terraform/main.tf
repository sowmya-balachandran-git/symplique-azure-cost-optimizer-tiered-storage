module "cosmosdb" {
  source           = "./modules/cosmosdb"
  resource_group   = "billing-archiver-rg"
  location         = "eastus"
  cosmos_name      = "billingcosmosdb001"      # must be globally unique
  cosmos_db        = "billingdb"
  cosmos_container = "billingRecords"
}

module "storage" {
  source            = "./modules/storage"
  resource_group    = "billing-archiver-rg"
  location          = "eastus"
  storage_name      = "billingarchivestg001"   # must be globally unique
  archive_container = "billing-archive"
  backup_container  = "billing-backups"
}

module "keyvault" {
  source         = "./modules/keyvault"
  resource_group = "billing-archiver-rg"
  location       = "eastus"
  keyvault_name  = "billing-archiver-kv-001"   # must be globally unique
}

module "functionapp" {
  source            = "./modules/functionapp"
  resource_group    = "billing-archiver-rg"
  location          = "eastus"
  function_name     = "billing-rehydrate-func"
  storage_name      = module.storage.storage_name
  archive_container = "billing-archive"
  keyvault_name     = module.keyvault.keyvault_name
  cosmos_db         = "billingdb"
  cosmos_container  = "billingRecords"
}

module "rehydrate" {
  source            = "./modules/rehydrate"
  resource_group    = "billing-archiver-rg"
  location          = "eastus"
  function_name     = "billing-rehydrate-blob-func"
  storage_name      = module.storage.storage_name
  archive_container = "billing-archive"
  keyvault_name     = module.keyvault.keyvault_name
}

module "monitoring" {
  source         = "./modules/monitoring"
  resource_group = "billing-archiver-rg"
  location       = "eastus"
  workspace_name = "billing-logs-ws"
  cosmos_id      = module.cosmosdb.cosmos_account_id
  storage_id     = module.storage.storage_account_id
  function_id    = module.functionapp.function_id
}

module "iam" {
  source                 = "./modules/iam"
  resource_group         = "billing-archiver-rg"
  principal_ids          = [
    module.functionapp.function_principal_id,
    module.rehydrate.function_principal_id
  ]
  storage_account_id     = module.storage.storage_account_id
  cosmos_account_id      = module.cosmosdb.cosmos_account_id
  keyvault_id            = module.keyvault.keyvault_id
}

module "archive_function" {
  source               = "./modules/archive_function"
  prefix               = var.prefix
  location             = var.location
  resource_group_name  = azurerm_resource_group.main.name
  key_vault_url        = module.keyvault.key_vault_uri
  cosmos_db_name       = var.cosmos_db_name
  cosmos_container     = var.cosmos_container
  blob_container       = var.blob_container
}
