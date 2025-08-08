output "cosmos_name" {
  value = module.cosmosdb.cosmos_name
}

output "storage_name" {
  value = module.storage.storage_name
}

output "function_name" {
  value = module.functionapp.function_name
}

output "rehydrate_function_name" {
  value = module.rehydrate.function_name
}

output "keyvault_name" {
  value = module.keyvault.keyvault_name
}

output "log_workspace_id" {
  value = module.monitoring.workspace_id
}
