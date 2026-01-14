# Azure Static Web App for frontend hosting
resource "azurerm_static_web_app" "main" {
  name                = "swa-${var.resource_prefix}"
  resource_group_name = var.resource_group_name
  location            = "eastus2"  # Static Web Apps have limited regions

  # Standard tier for custom domains and advanced features
  sku_tier = "Standard"
  sku_size = "Standard"

  # Managed identity for accessing Azure services
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Custom domain (optional)
resource "azurerm_static_web_app_custom_domain" "main" {
  count               = var.custom_domain != "" ? 1 : 0
  static_web_app_id   = azurerm_static_web_app.main.id
  domain_name         = var.custom_domain
  validation_type     = "cname-delegation"
}
