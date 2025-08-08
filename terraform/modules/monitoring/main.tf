resource "azurerm_log_analytics_workspace" "la" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

resource "azurerm_monitor_diagnostic_setting" "cosmos_diag" {
  name                       = "cosmos-diagnostics"
  target_resource_id         = var.cosmos_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.la.id

  log {
    category = "DataPlaneRequests"
    enabled  = true
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage_diag" {
  name                       = "storage-diagnostics"
  target_resource_id         = var.storage_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.la.id

  log {
    category = "StorageRead"
    enabled  = true
  }
  log {
    category = "StorageWrite"
    enabled  = true
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "func_diag" {
  name                       = "func-diagnostics"
  target_resource_id         = var.function_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.la.id

  log {
    category = "AppServiceHTTPLogs"
    enabled  = true
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

output "workspace_id" {
  value = azurerm_log_analytics_workspace.la.id
}
