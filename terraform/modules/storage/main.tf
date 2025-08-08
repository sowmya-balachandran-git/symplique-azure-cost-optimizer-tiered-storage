resource "azurerm_storage_account" "storage" {
  name                     = var.storage_name
  resource_group_name      = var.resource_group
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = false

  enable_blob_versioning = true
  min_tls_version        = "TLS1_2"
}

resource "azurerm_storage_container" "archive" {
  name                  = var.archive_container
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "backups" {
  name                  = var.backup_container
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

output "storage_name" {
  value = azurerm_storage_account.storage.name
}

output "storage_account_id" {
  value = azurerm_storage_account.storage.id
}
