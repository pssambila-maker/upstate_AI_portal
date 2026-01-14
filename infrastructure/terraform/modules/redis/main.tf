# Azure Redis Cache for LiteLLM load balancing and rate limiting
resource "azurerm_redis_cache" "main" {
  name                = "redis-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Premium tier for VNet integration and persistence
  capacity = 1
  family   = "P"
  sku_name = "Premium"

  # HIPAA: Disable non-SSL port
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  # HIPAA: Disable public network access
  public_network_access_enabled = false

  # Redis configuration
  redis_configuration {
    enable_authentication           = true
    maxmemory_policy                = "allkeys-lru"
    maxmemory_reserved              = 50
    maxfragmentationmemory_reserved = 50

    # Enable data persistence for reliability
    rdb_backup_enabled = true
    rdb_backup_frequency = 60  # Minutes
    rdb_backup_max_snapshot_count = 1
  }

  # Zones for high availability
  zones = ["1", "2"]

  tags = var.tags
}

# Private endpoint for Redis
resource "azurerm_private_endpoint" "redis" {
  name                = "pe-${azurerm_redis_cache.main.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-redis"
    private_connection_resource_id = azurerm_redis_cache.main.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-redis"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = var.tags
}

# Store Redis connection details in Key Vault
resource "azurerm_key_vault_secret" "redis_host" {
  name         = "redis-host"
  value        = azurerm_redis_cache.main.hostname
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_redis_cache.main]
}

resource "azurerm_key_vault_secret" "redis_password" {
  name         = "redis-password"
  value        = azurerm_redis_cache.main.primary_access_key
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_redis_cache.main]
}

# Diagnostic settings for audit logging
resource "azurerm_monitor_diagnostic_setting" "redis" {
  name                       = "diag-${azurerm_redis_cache.main.name}"
  target_resource_id         = azurerm_redis_cache.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Connected clients logs
  enabled_log {
    category = "ConnectedClientList"
  }

  # Metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
