# Storage Account for RAG documents and general storage
resource "azurerm_storage_account" "main" {
  name                = "st${replace(var.resource_prefix, "-", "")}rag"  # Remove hyphens for storage account name
  resource_group_name = var.resource_group_name
  location            = var.location

  # Premium performance for low latency
  account_tier             = "Standard"
  account_replication_type = "GRS"  # Geo-redundant for disaster recovery
  account_kind             = "StorageV2"

  # HIPAA: Enable HTTPS only
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  # HIPAA: Disable public blob access
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false

  # Enable hierarchical namespace for ADLS Gen2 (better for large files)
  is_hns_enabled = true

  # Blob properties
  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = var.tags
}

# Container for RAG documents
resource "azurerm_storage_container" "rag_documents" {
  name                  = "rag-documents"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Container for prompt templates
resource "azurerm_storage_container" "prompts" {
  name                  = "prompt-templates"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Private endpoint for Blob storage
resource "azurerm_private_endpoint" "blob" {
  name                = "pe-${azurerm_storage_account.main.name}-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-blob"
    private_dns_zone_ids = [var.private_dns_zone_ids.blob]
  }

  tags = var.tags
}

# Private endpoint for DFS (ADLS Gen2)
resource "azurerm_private_endpoint" "dfs" {
  name                = "pe-${azurerm_storage_account.main.name}-dfs"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-dfs"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-dfs"
    private_dns_zone_ids = [var.private_dns_zone_ids.dfs]
  }

  tags = var.tags
}

# Diagnostic settings for audit logging
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "diag-${azurerm_storage_account.main.name}"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default/"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Storage logs
  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  # Metrics
  metric {
    category = "Transaction"
    enabled  = true
  }
}
