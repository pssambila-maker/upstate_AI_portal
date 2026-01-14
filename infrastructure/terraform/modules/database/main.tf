# PostgreSQL Flexible Server for LiteLLM persistence
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-${var.resource_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  # HIPAA: Use delegated subnet (private networking)
  delegated_subnet_id = var.database_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  administrator_login    = "litellm_admin"
  administrator_password = var.admin_password

  # Version
  version = "16"

  # SKU - General Purpose with high availability
  sku_name = "GP_Standard_D2s_v3"

  # Storage
  storage_mb = 32768  # 32 GB

  # HIPAA: Backup configuration
  backup_retention_days        = 35
  geo_redundant_backup_enabled = true

  # HIPAA: High availability (zone-redundant)
  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  zone = "1"

  # Maintenance window
  maintenance_window {
    day_of_week  = 0  # Sunday
    start_hour   = 2
    start_minute = 0
  }

  tags = var.tags

  depends_on = [var.private_dns_zone_id]
}

# Create database for LiteLLM
resource "azurerm_postgresql_flexible_server_database" "litellm" {
  name      = "litellm_db"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Enable pgvector extension for RAG (future use)
resource "azurerm_postgresql_flexible_server_configuration" "pgvector" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "VECTOR,PGCRYPTO"
}

# Store database connection details in Key Vault
resource "azurerm_key_vault_secret" "postgres_host" {
  name         = "postgres-host"
  value        = azurerm_postgresql_flexible_server.main.fqdn
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_postgresql_flexible_server.main]
}

resource "azurerm_key_vault_secret" "postgres_user" {
  name         = "postgres-user"
  value        = azurerm_postgresql_flexible_server.main.administrator_login
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_postgresql_flexible_server.main]
}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-password"
  value        = var.admin_password
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "postgres_database" {
  name         = "postgres-database"
  value        = azurerm_postgresql_flexible_server_database.litellm.name
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_postgresql_flexible_server_database.litellm]
}

# Diagnostic settings for audit logging
resource "azurerm_monitor_diagnostic_setting" "postgres" {
  name                       = "diag-${azurerm_postgresql_flexible_server.main.name}"
  target_resource_id         = azurerm_postgresql_flexible_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # PostgreSQL logs
  enabled_log {
    category = "PostgreSQLLogs"
  }

  # Metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
