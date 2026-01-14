provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azuread" {}

# Local variables
locals {
  common_tags = {
    Project             = "Upstate-AI-Portal"
    Environment         = var.environment
    ManagedBy           = "Terraform"
    ComplianceLevel     = "HIPAA"
    CostCenter          = var.cost_center
    DataClassification  = "PHI"
  }

  resource_prefix = "${var.org_name}-${var.environment}"
}

# Main resource group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}-ai-portal"
  location = var.location
  tags     = local.common_tags
}

# Networking module (deployed first - required by all other modules)
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  vnet_address_space  = var.vnet_address_space
  allowed_ip_ranges   = var.allowed_ip_ranges
  tags                = local.common_tags
}

# Monitoring module (deployed early for observability)
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  resource_prefix     = local.resource_prefix
  log_retention_days  = var.log_retention_days
  tags                = local.common_tags
}

# Key Vault module (required by most other modules)
module "key_vault" {
  source = "./modules/key-vault"

  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  environment              = var.environment
  resource_prefix          = local.resource_prefix
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  private_dns_zone_id      = module.networking.key_vault_private_dns_zone_id
  tenant_id                = data.azurerm_client_config.current.tenant_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                     = local.common_tags

  depends_on = [module.networking, module.monitoring]
}

# Azure OpenAI module
module "azure_openai" {
  source = "./modules/azure-openai"

  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  environment              = var.environment
  resource_prefix          = local.resource_prefix
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  private_dns_zone_id      = module.networking.openai_private_dns_zone_id
  key_vault_id             = module.key_vault.key_vault_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                     = local.common_tags

  depends_on = [module.key_vault]
}

# PostgreSQL database for LiteLLM
module "database" {
  source = "./modules/database"

  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  environment              = var.environment
  resource_prefix          = local.resource_prefix
  database_subnet_id       = module.networking.database_subnet_id
  private_dns_zone_id      = module.networking.postgres_private_dns_zone_id
  key_vault_id             = module.key_vault.key_vault_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  admin_password           = var.db_admin_password
  tags                     = local.common_tags

  depends_on = [module.networking, module.key_vault]
}

# Redis cache for LiteLLM
module "redis" {
  source = "./modules/redis"

  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  environment              = var.environment
  resource_prefix          = local.resource_prefix
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  private_dns_zone_id      = module.networking.redis_private_dns_zone_id
  key_vault_id             = module.key_vault.key_vault_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                     = local.common_tags

  depends_on = [module.networking, module.key_vault]
}

# Container Apps for LiteLLM
module "container_apps" {
  source = "./modules/container-apps"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  environment                = var.environment
  resource_prefix            = local.resource_prefix
  container_apps_subnet_id   = module.networking.container_apps_subnet_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  # LiteLLM configuration
  azure_openai_endpoint = module.azure_openai.endpoint
  azure_openai_key      = module.azure_openai.primary_key
  litellm_master_key    = var.litellm_master_key
  postgres_host         = module.database.fqdn
  postgres_user         = module.database.admin_username
  postgres_password     = var.db_admin_password
  postgres_database     = "litellm_db"
  redis_host            = module.redis.hostname
  redis_password        = module.redis.primary_access_key

  tags = local.common_tags

  depends_on = [module.azure_openai, module.database, module.redis]
}

# API Management
module "apim" {
  source = "./modules/apim"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  environment                = var.environment
  resource_prefix            = local.resource_prefix
  apim_subnet_id             = module.networking.apim_subnet_id
  publisher_name             = var.apim_publisher_name
  publisher_email            = var.apim_publisher_email
  litellm_backend_url        = module.container_apps.litellm_fqdn
  litellm_master_key         = var.litellm_master_key
  key_vault_id               = module.key_vault.key_vault_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  azure_ad_tenant_id         = data.azurerm_client_config.current.tenant_id
  azure_ad_client_id         = var.azure_ad_client_id
  tags                       = local.common_tags

  depends_on = [module.container_apps, module.key_vault]
}

# Storage for RAG documents (optional)
module "storage" {
  source = "./modules/storage"

  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  environment              = var.environment
  resource_prefix          = local.resource_prefix
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  private_dns_zone_ids     = {
    blob = module.networking.blob_private_dns_zone_id
    dfs  = module.networking.dfs_private_dns_zone_id
  }
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.common_tags

  depends_on = [module.networking]
}

# Static Web App for frontend
module "static_web_app" {
  source = "./modules/static-web-app"

  resource_group_name = azurerm_resource_group.main.name
  environment         = var.environment
  resource_prefix     = local.resource_prefix
  custom_domain       = var.frontend_custom_domain
  tags                = local.common_tags
}

# Current Azure client configuration
data "azurerm_client_config" "current" {}
