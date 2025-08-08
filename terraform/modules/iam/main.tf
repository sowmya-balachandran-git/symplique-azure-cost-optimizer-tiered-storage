locals {
  principals = { for p in var.principal_ids : p => p }
}

# For each principal, bind same roles (Storage Blob Data Contributor, Cosmos DB Operator Role, Key Vault Secrets User)
resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  for_each = local.principals
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.key
}

resource "azurerm_role_assignment" "cosmos_db_operator" {
  for_each = local.principals
  scope                = var.cosmos_account_id
  role_definition_name = "Cosmos DB Operator Role"
  principal_id         = each.key
}

resource "azurerm_role_assignment" "keyvault_secrets_user" {
  for_each = local.principals
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.key
}
