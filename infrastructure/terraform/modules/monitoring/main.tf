# Log Analytics Workspace for centralized logging
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"

  # HIPAA: Minimum 365-day retention
  retention_in_days = var.log_retention_days

  # Data export and archival
  daily_quota_gb = -1  # No quota limit (pay as you go)

  tags = var.tags
}

# Application Insights for application telemetry
resource "azurerm_application_insights" "main" {
  name                = "appi-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  # Sampling configuration (100% for HIPAA compliance - no data loss)
  sampling_percentage = 100

  # Disable local authentication (use Azure AD only)
  local_authentication_disabled = false  # Set to true after AD integration

  tags = var.tags
}

# Action Group for operational alerts
resource "azurerm_monitor_action_group" "ops_team" {
  name                = "ag-ops-${var.resource_prefix}"
  resource_group_name = var.resource_group_name
  short_name          = "ops"

  email_receiver {
    name          = "ops-email"
    email_address = var.ops_team_email
  }

  tags = var.tags
}

# Action Group for security alerts
resource "azurerm_monitor_action_group" "security_team" {
  name                = "ag-security-${var.resource_prefix}"
  resource_group_name = var.resource_group_name
  short_name          = "security"

  email_receiver {
    name          = "security-email"
    email_address = var.security_team_email
  }

  tags = var.tags
}
