output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "blob_endpoint" {
  description = "Blob storage endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "dfs_endpoint" {
  description = "ADLS Gen2 endpoint"
  value       = azurerm_storage_account.main.primary_dfs_endpoint
}

output "primary_access_key" {
  description = "Primary access key for storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}
