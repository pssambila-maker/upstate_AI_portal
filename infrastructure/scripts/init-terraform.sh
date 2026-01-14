#!/bin/bash

# Terraform Backend Initialization Script
# Creates Azure Storage Account for Terraform state management

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================="
echo "Terraform Backend Initialization"
echo "========================================="
echo ""

# Configuration
LOCATION=${LOCATION:-"eastus2"}
BACKEND_RG="rg-upstate-tfstate"
STORAGE_ACCOUNT="stupstatetf$(date +%s | tail -c 8)"  # Unique name
CONTAINER_NAME="tfstate"

echo -e "${YELLOW}Creating Terraform backend resources...${NC}"
echo "Resource Group: $BACKEND_RG"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Location: $LOCATION"
echo ""

# Check if Azure CLI is logged in
if ! az account show > /dev/null 2>&1; then
    echo "Please login to Azure CLI first: az login"
    exit 1
fi

# Create resource group
echo "Creating resource group..."
az group create \
  --name "$BACKEND_RG" \
  --location "$LOCATION" \
  --tags "Purpose=TerraformState" "ManagedBy=Script"

# Create storage account
echo "Creating storage account..."
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$BACKEND_RG" \
  --location "$LOCATION" \
  --sku Standard_GRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group "$BACKEND_RG" \
  --account-name "$STORAGE_ACCOUNT" \
  --query '[0].value' -o tsv)

# Create container
echo "Creating blob container..."
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$ACCOUNT_KEY" \
  --public-access off

# Enable versioning
echo "Enabling blob versioning..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$BACKEND_RG" \
  --enable-versioning true

echo ""
echo -e "${GREEN}Backend resources created successfully!${NC}"
echo ""
echo "========================================="
echo "Backend Configuration"
echo "========================================="
echo "resource_group_name  = \"$BACKEND_RG\""
echo "storage_account_name = \"$STORAGE_ACCOUNT\""
echo "container_name       = \"$CONTAINER_NAME\""
echo "key                  = \"terraform.tfstate\""
echo ""
echo "Create a backend config file (e.g., environments/dev-backend.tfvars):"
echo ""
cat << EOF
resource_group_name  = "$BACKEND_RG"
storage_account_name = "$STORAGE_ACCOUNT"
container_name       = "$CONTAINER_NAME"
key                  = "dev.terraform.tfstate"
EOF
echo ""
echo "Then initialize with:"
echo "  terraform init -backend-config=environments/dev-backend.tfvars"
echo "========================================="
