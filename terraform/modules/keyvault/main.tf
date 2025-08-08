data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                        = var.keyvault_name
  location                    = var.location
  resource_group_name         = var.resource_group
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_enabled         = true
  soft_delete_retention_days  = 7
}

output "keyvault_name" {
  value = azurerm_key_vault.kv.name
}

output "keyvault_id" {
  value = azurerm_key_vault.kv.id
}
