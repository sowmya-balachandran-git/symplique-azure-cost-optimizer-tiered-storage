resource "azurerm_cosmosdb_account" "cosmos" {
  name                = var.cosmos_name
  location            = var.location
  resource_group_name = var.resource_group
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = var.cosmos_db
  resource_group_name = var.resource_group
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                = var.cosmos_container
  resource_group_name = var.resource_group
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_path  = "/partitionKey"
  throughput          = 400
}

output "cosmos_name" {
  value = azurerm_cosmosdb_account.cosmos.name
}

output "cosmos_account_id" {
  value = azurerm_cosmosdb_account.cosmos.id
}
