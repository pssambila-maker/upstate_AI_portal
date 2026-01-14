# Azure OpenAI Service
resource "azurerm_cognitive_account" "openai" {
  name                = "aoai-${var.resource_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "OpenAI"
  sku_name            = "S0"

  # Subdomain for custom endpoint
  custom_subdomain_name = "aoai-${var.resource_prefix}"

  # HIPAA: Disable public network access
  public_network_access_enabled = false

  # Managed identity for Azure service integration
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# GPT-4o deployment
resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = "2024-11-20"
  }

  sku {
    name     = "Standard"
    capacity = 100  # TPM in thousands (100K tokens per minute)
  }
}

# GPT-4 Turbo deployment
resource "azurerm_cognitive_deployment" "gpt4_turbo" {
  name                 = "gpt-4-turbo"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4"
    version = "turbo-2024-04-09"
  }

  sku {
    name     = "Standard"
    capacity = 50  # TPM in thousands
  }
}

# Text embedding model (for RAG)
resource "azurerm_cognitive_deployment" "text_embedding" {
  name                 = "text-embedding-3-large"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "text-embedding-3-large"
    version = "1"
  }

  sku {
    name     = "Standard"
    capacity = 10  # TPM in thousands
  }
}

# Private endpoint for Azure OpenAI
resource "azurerm_private_endpoint" "openai" {
  name                = "pe-${azurerm_cognitive_account.openai.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-openai"
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-openai"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = var.tags
}

# Store Azure OpenAI endpoint in Key Vault
resource "azurerm_key_vault_secret" "openai_endpoint" {
  name         = "azure-openai-endpoint"
  value        = azurerm_cognitive_account.openai.endpoint
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_cognitive_account.openai]
}

# Store Azure OpenAI primary key in Key Vault
resource "azurerm_key_vault_secret" "openai_key" {
  name         = "azure-openai-key"
  value        = azurerm_cognitive_account.openai.primary_access_key
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_cognitive_account.openai]
}

# Diagnostic settings for audit logging
resource "azurerm_monitor_diagnostic_setting" "openai" {
  name                       = "diag-${azurerm_cognitive_account.openai.name}"
  target_resource_id         = azurerm_cognitive_account.openai.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Request and response logs
  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "RequestResponse"
  }

  # Metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
