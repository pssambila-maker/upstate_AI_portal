#!/bin/bash

# Azure AI Portal Deployment Script
# Deploys the complete infrastructure using Terraform

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="$(dirname "$0")/../terraform"
AUTO_APPROVE=${AUTO_APPROVE:-false}

echo "========================================="
echo "Upstate AI Portal Deployment"
echo "========================================="
echo "Environment: $ENVIRONMENT"
echo "Terraform Directory: $TERRAFORM_DIR"
echo ""

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}Error: Environment must be dev, staging, or prod${NC}"
    exit 1
fi

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI not found. Please install: https://aka.ms/azure-cli${NC}"
    exit 1
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform not found. Please install: https://terraform.io${NC}"
    exit 1
fi

# Check Azure login
if ! az account show > /dev/null 2>&1; then
    echo -e "${RED}Error: Not logged in to Azure CLI. Please run: az login${NC}"
    exit 1
fi

SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo -e "${GREEN}✓ Logged in to Azure subscription: $SUBSCRIPTION_NAME${NC}"

# Check for required files
if [ ! -f "$TERRAFORM_DIR/environments/${ENVIRONMENT}.tfvars" ]; then
    echo -e "${RED}Error: Environment file not found: $TERRAFORM_DIR/environments/${ENVIRONMENT}.tfvars${NC}"
    echo "Please create it based on terraform.tfvars.example"
    exit 1
fi

if [ ! -f "$TERRAFORM_DIR/environments/${ENVIRONMENT}-backend.tfvars" ]; then
    echo -e "${YELLOW}Warning: Backend config not found. Run init-terraform.sh first.${NC}"
    read -p "Continue anyway? (yes/no): " CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
        exit 0
    fi
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"
echo ""

# Navigate to Terraform directory
cd "$TERRAFORM_DIR"

# Step 1: Initialize Terraform
echo "========================================="
echo "Step 1: Initializing Terraform"
echo "========================================="

if [ -f "environments/${ENVIRONMENT}-backend.tfvars" ]; then
    terraform init -backend-config="environments/${ENVIRONMENT}-backend.tfvars" -upgrade
else
    terraform init -upgrade
fi

echo -e "${GREEN}✓ Terraform initialized${NC}"
echo ""

# Step 2: Validate configuration
echo "========================================="
echo "Step 2: Validating Configuration"
echo "========================================="

terraform validate

echo -e "${GREEN}✓ Configuration valid${NC}"
echo ""

# Step 3: Plan deployment
echo "========================================="
echo "Step 3: Planning Deployment"
echo "========================================="

terraform plan \
  -var-file="environments/${ENVIRONMENT}.tfvars" \
  -out="${ENVIRONMENT}.tfplan"

echo ""
echo -e "${GREEN}✓ Plan created: ${ENVIRONMENT}.tfplan${NC}"
echo ""

# Step 4: Review and confirm
if [ "$AUTO_APPROVE" != "true" ]; then
    echo "========================================="
    echo "Review the plan above carefully"
    echo "========================================="
    echo ""
    read -p "Do you want to proceed with deployment? (yes/no): " CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${YELLOW}Deployment cancelled${NC}"
        rm -f "${ENVIRONMENT}.tfplan"
        exit 0
    fi
fi

# Step 5: Apply infrastructure
echo ""
echo "========================================="
echo "Step 4: Applying Infrastructure"
echo "========================================="
echo ""

if [ "$AUTO_APPROVE" = "true" ]; then
    terraform apply "${ENVIRONMENT}.tfplan"
else
    terraform apply "${ENVIRONMENT}.tfplan"
fi

# Clean up plan file
rm -f "${ENVIRONMENT}.tfplan"

echo ""
echo -e "${GREEN}✓ Infrastructure deployed successfully!${NC}"
echo ""

# Step 6: Retrieve outputs
echo "========================================="
echo "Step 5: Deployment Summary"
echo "========================================="

terraform output -json > "${ENVIRONMENT}-outputs.json"

APIM_URL=$(terraform output -raw apim_gateway_url 2>/dev/null || echo "N/A")
FRONTEND_URL=$(terraform output -raw static_web_app_url 2>/dev/null || echo "N/A")
LITELLM_URL=$(terraform output -raw litellm_url 2>/dev/null || echo "N/A")
KV_URI=$(terraform output -raw key_vault_uri 2>/dev/null || echo "N/A")

echo ""
echo -e "${GREEN}Deployment Complete!${NC}"
echo ""
echo "APIM Gateway URL: $APIM_URL"
echo "Frontend URL: $FRONTEND_URL"
echo "LiteLLM URL (internal): $LITELLM_URL"
echo "Key Vault URI: $KV_URI"
echo ""
echo "Outputs saved to: ${ENVIRONMENT}-outputs.json"
echo ""

# Step 7: Next steps
echo "========================================="
echo "Next Steps"
echo "========================================="
echo ""
echo "1. Configure Azure AD Application:"
echo "   - Add redirect URI: $FRONTEND_URL"
echo "   - Configure app roles: Clinician, BillingStaff, Admin, Developer"
echo ""
echo "2. Deploy Frontend Application:"
echo "   - Set NEXT_PUBLIC_APIM_ENDPOINT=$APIM_URL"
echo "   - Deploy via GitHub Actions with deployment token"
echo ""
echo "3. Test Deployment:"
echo "   - Run: ./validate-compliance.sh"
echo "   - Test APIM: curl $APIM_URL/genai/models"
echo ""
echo "4. Review Security:"
echo "   - Check Key Vault: az keyvault list"
echo "   - Verify private endpoints: az network private-endpoint list"
echo ""
echo "========================================="

# Optional: Run compliance validation
read -p "Run compliance validation now? (yes/no): " RUN_VALIDATION
if [ "$RUN_VALIDATION" = "yes" ]; then
    cd ../scripts
    ./validate-compliance.sh "$ENVIRONMENT"
fi
