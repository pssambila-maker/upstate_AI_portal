# Key Vault for secrets management
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "kv-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # HIPAA: Enable soft-delete and purge protection
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  # HIPAA: Disable public network access
  public_network_access_enabled = false

  # Network ACLs
  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  # RBAC authorization (recommended over access policies)
  enable_rbac_authorization = true

  tags = var.tags
}

# Private endpoint for Key Vault
resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-${azurerm_key_vault.main.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-keyvault"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = var.tags
}

# Diagnostic settings for audit logging
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-${azurerm_key_vault.main.name}"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Audit logs
  enabled_log {
    category = "AuditEvent"
  }

  # Metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Role assignment for Terraform service principal (to manage secrets)
resource "azurerm_role_assignment" "terraform_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
