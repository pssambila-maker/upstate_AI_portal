output "vnet_id" {
  description = "ID of the VNet"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the VNet"
  value       = azurerm_virtual_network.main.name
}

output "apim_subnet_id" {
  description = "ID of the APIM subnet"
  value       = azurerm_subnet.apim.id
}

output "container_apps_subnet_id" {
  description = "ID of the Container Apps subnet"
  value       = azurerm_subnet.container_apps.id
}

output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = azurerm_subnet.database.id
}

output "private_endpoint_subnet_id" {
  description = "ID of the private endpoints subnet"
  value       = azurerm_subnet.private_endpoints.id
}

output "bastion_subnet_id" {
  description = "ID of the Bastion subnet"
  value       = azurerm_subnet.bastion.id
}

# Private DNS Zone IDs
output "openai_private_dns_zone_id" {
  description = "ID of the Azure OpenAI private DNS zone"
  value       = azurerm_private_dns_zone.openai.id
}

output "postgres_private_dns_zone_id" {
  description = "ID of the PostgreSQL private DNS zone"
  value       = azurerm_private_dns_zone.postgres.id
}

output "redis_private_dns_zone_id" {
  description = "ID of the Redis private DNS zone"
  value       = azurerm_private_dns_zone.redis.id
}

output "key_vault_private_dns_zone_id" {
  description = "ID of the Key Vault private DNS zone"
  value       = azurerm_private_dns_zone.key_vault.id
}

output "blob_private_dns_zone_id" {
  description = "ID of the Blob Storage private DNS zone"
  value       = azurerm_private_dns_zone.blob.id
}

output "dfs_private_dns_zone_id" {
  description = "ID of the ADLS Gen2 private DNS zone"
  value       = azurerm_private_dns_zone.dfs.id
}
