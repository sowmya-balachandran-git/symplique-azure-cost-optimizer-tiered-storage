variable "principal_ids" {
  type = list(string)
  description = "List of principal IDs to assign roles to"
}

variable "storage_account_id" { type = string }
variable "cosmos_account_id" { type = string }
variable "keyvault_id" { type = string }
