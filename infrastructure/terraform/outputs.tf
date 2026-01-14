output "resource_group_name" {
  description = "Name of the main resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the main resource group"
  value       = azurerm_resource_group.main.location
}

# Networking outputs
output "vnet_id" {
  description = "ID of the main VNet"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the main VNet"
  value       = module.networking.vnet_name
}

# Monitoring outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.monitoring.application_insights_instrumentation_key
  sensitive   = true
}

# Key Vault outputs
output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = module.key_vault.key_vault_id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.key_vault_uri
}

# Azure OpenAI outputs
output "azure_openai_endpoint" {
  description = "Azure OpenAI service endpoint"
  value       = module.azure_openai.endpoint
}

output "azure_openai_id" {
  description = "Azure OpenAI service ID"
  value       = module.azure_openai.id
}

# Database outputs
output "postgres_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = module.database.fqdn
}

output "postgres_database_name" {
  description = "PostgreSQL database name"
  value       = "litellm_db"
}

# Redis outputs
output "redis_hostname" {
  description = "Redis cache hostname"
  value       = module.redis.hostname
}

# Container Apps outputs
output "litellm_fqdn" {
  description = "LiteLLM Container App FQDN (internal)"
  value       = module.container_apps.litellm_fqdn
}

output "litellm_url" {
  description = "LiteLLM Container App URL (internal)"
  value       = "https://${module.container_apps.litellm_fqdn}"
}

# APIM outputs
output "apim_gateway_url" {
  description = "APIM gateway URL for AI services"
  value       = module.apim.gateway_url
}

output "apim_management_url" {
  description = "APIM management portal URL"
  value       = module.apim.management_url
}

output "apim_developer_portal_url" {
  description = "APIM developer portal URL"
  value       = module.apim.developer_portal_url
}

# Storage outputs
output "storage_account_name" {
  description = "Storage account name for RAG documents"
  value       = module.storage.storage_account_name
}

output "storage_blob_endpoint" {
  description = "Blob storage endpoint"
  value       = module.storage.blob_endpoint
}

# Frontend outputs
output "static_web_app_url" {
  description = "Static Web App default URL"
  value       = "https://${module.static_web_app.default_hostname}"
}

output "static_web_app_deployment_token" {
  description = "Static Web App deployment token (use for GitHub Actions)"
  value       = module.static_web_app.api_key
  sensitive   = true
}

# Deployment information
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment     = var.environment
    location        = var.location
    apim_url        = module.apim.gateway_url
    frontend_url    = "https://${module.static_web_app.default_hostname}"
    litellm_url     = "https://${module.container_apps.litellm_fqdn}"
    key_vault_uri   = module.key_vault.key_vault_uri
  }
}

# Next steps instructions
output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
    ========================================
    Deployment Complete!
    ========================================

    APIM Gateway URL: ${module.apim.gateway_url}
    Frontend URL: https://${module.static_web_app.default_hostname}

    Next Steps:
    1. Configure Azure AD app registration:
       - Add redirect URI: https://${module.static_web_app.default_hostname}
       - Configure app roles: Clinician, BillingStaff, Admin, Developer

    2. Deploy frontend application:
       - Set NEXT_PUBLIC_APIM_ENDPOINT=${module.apim.gateway_url}
       - Set NEXT_PUBLIC_AZURE_AD_CLIENT_ID=${var.azure_ad_client_id}
       - Deploy via GitHub Actions with deployment token (see outputs)

    3. Test the deployment:
       - Run: ./validate-compliance.sh
       - Test APIM endpoint with valid Azure AD token

    4. Review Key Vault secrets:
       - URI: ${module.key_vault.key_vault_uri}
       - Verify all secrets are stored correctly

    ========================================
  EOT
}
