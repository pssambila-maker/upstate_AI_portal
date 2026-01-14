variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "log_retention_days" {
  description = "Log retention period in days (HIPAA requires 365)"
  type        = number
  default     = 365
}

variable "ops_team_email" {
  description = "Email address for operational alerts"
  type        = string
  default     = "ops@upstate.com"
}

variable "security_team_email" {
  description = "Email address for security alerts"
  type        = string
  default     = "security@upstate.com"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
