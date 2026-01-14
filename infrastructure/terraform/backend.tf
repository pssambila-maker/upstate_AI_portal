terraform {
  backend "azurerm" {
    # Backend configuration will be provided via init command or backend config file
    # Example: terraform init -backend-config="environments/dev-backend.tfvars"
    #
    # Required values:
    # - resource_group_name  = "rg-upstate-tfstate"
    # - storage_account_name = "stupstatetfstate<unique>"
    # - container_name       = "tfstate"
    # - key                  = "terraform.tfstate"
  }

  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
