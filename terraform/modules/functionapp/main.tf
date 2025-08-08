resource "azurerm_app_service_plan" "plan" {
  name                = "${var.function_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_storage_account" "func_sa" {
  name                     = "${var.function_name}sa"
  resource_group_name      = var.resource_group
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_linux_function_app" "func" {
  name                       = var.function_name
  location                   = var.location
  resource_group_name        = var.resource_group
  service_plan_id            = azurerm_app_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.func_sa.name
  storage_account_access_key = azurerm_storage_account.func_sa.primary_access_key
  version                    = "~4"

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    KEYVAULT_NAME            = var.keyvault_name
    KEYVAULT_SECRET_NAME     = "CosmosDBConnectionString"
    BLOB_ACCOUNT_URL         = "https://${var.storage_name}.blob.core.windows.net"
    BLOB_CONTAINER           = var.archive_container
    COSMOS_DB                = var.cosmos_db
    COSMOS_CONTAINER         = var.cosmos_container
  }
}

output "function_name" {
  value = azurerm_linux_function_app.func.name
}

output "function_id" {
  value = azurerm_linux_function_app.func.id
}

output "function_principal_id" {
  value = azurerm_linux_function_app.func.identity[0].principal_id
}
