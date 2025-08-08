resource "azurerm_storage_account" "archive_func_sa" {
  name                     = "${var.prefix}archfuncsa"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "archive_func_container" {
  name                  = "azure-webjobs-hosts"
  storage_account_name  = azurerm_storage_account.archive_func_sa.name
  container_access_type = "private"
}

resource "azurerm_app_service_plan" "archive_func_plan" {
  name                = "${var.prefix}-archive-func-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "archive_func" {
  name                       = "${var.prefix}-archive-func"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = azurerm_app_service_plan.archive_func_plan.id
  storage_account_name       = azurerm_storage_account.archive_func_sa.name
  storage_account_access_key = azurerm_storage_account.archive_func_sa.primary_access_key
  version                    = "~4"
  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME        = "python"
    AzureWebJobsStorage             = azurerm_storage_account.archive_func_sa.primary_connection_string
    KEYVAULT_URL                    = var.key_vault_url
    COSMOS_DB_NAME                  = var.cosmos_db_name
    COSMOS_CONTAINER                = var.cosmos_container
    BLOB_CONTAINER                   = var.blob_container
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
}
