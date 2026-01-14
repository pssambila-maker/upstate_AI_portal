variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

variable "org_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "upstate"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Healthcare-AI"
}

# Networking
variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "allowed_ip_ranges" {
  description = "IP ranges allowed for administrative access"
  type        = list(string)
  default     = []
}

# Monitoring
variable "log_retention_days" {
  description = "Log retention period in days (HIPAA requires 365)"
  type        = number
  default     = 365
  validation {
    condition     = var.log_retention_days >= 365
    error_message = "Log retention must be at least 365 days for HIPAA compliance."
  }
}

# Database
variable "db_admin_password" {
  description = "PostgreSQL admin password (stored in Key Vault)"
  type        = string
  sensitive   = true
}

# LiteLLM
variable "litellm_master_key" {
  description = "Master key for LiteLLM proxy authentication"
  type        = string
  sensitive   = true
}

# API Management
variable "apim_publisher_name" {
  description = "APIM publisher organization name"
  type        = string
  default     = "Upstate Healthcare"
}

variable "apim_publisher_email" {
  description = "APIM publisher email address"
  type        = string
}

# Azure AD
variable "azure_ad_client_id" {
  description = "Azure AD application client ID for portal authentication"
  type        = string
}

# Frontend
variable "frontend_custom_domain" {
  description = "Custom domain for frontend (optional)"
  type        = string
  default     = ""
}

# External AI Providers (optional)
variable "anthropic_api_key" {
  description = "Anthropic API key for Claude models (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "google_project_id" {
  description = "Google Cloud project ID for Vertex AI (optional)"
  type        = string
  default     = ""
}
