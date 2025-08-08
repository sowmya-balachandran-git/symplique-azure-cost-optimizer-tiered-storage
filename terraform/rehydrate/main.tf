resource "azurerm_app_service_plan" "rehydrate_plan" {
  name                = "${var.function_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_storage_account" "rehydrate_sa" {
  name                     = "${var.function_name}sa"
  resource_group_name      = var.resource_group
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_linux_function_app" "rehydrate_func" {
  name                       = var.function_name
  location                   = var.location
  resource_group_name        = var.resource_group
  service_plan_id            = azurerm_app_service_plan.rehydrate_plan.id
  storage_account_name       = azurerm_storage_account.rehydrate_sa.name
  storage_account_access_key = azurerm_storage_account.rehydrate_sa.primary_access_key
  version                    = "~4"

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    BLOB_ACCOUNT_URL         = "https://${var.storage_name}.blob.core.windows.net"
    BLOB_CONTAINER           = var.archive_container
    KEYVAULT_NAME            = var.keyvault_name
  }
}

output "function_name" {
  value = azurerm_linux_function_app.rehydrate_func.name
}

output "function_principal_id" {
  value = azurerm_linux_function_app.rehydrate_func.identity[0].principal_id
}
