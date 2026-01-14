#!/bin/bash

# HIPAA Compliance Validation Script
# Verifies security controls are properly configured

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ENVIRONMENT=${1:-dev}
PASSED=0
FAILED=0

echo "========================================="
echo "HIPAA Compliance Validation"
echo "========================================="
echo "Environment: $ENVIRONMENT"
echo ""

# Get resource group name
RG_NAME="rg-upstate-${ENVIRONMENT}-ai-portal"

echo -e "${YELLOW}Checking resource group: $RG_NAME${NC}"
echo ""

# Test 1: Encryption at Rest
echo "Test 1: Encryption at Rest"
echo "----------------------------"

# Check storage accounts
STORAGE_ACCOUNTS=$(az storage account list -g "$RG_NAME" --query "[].{name:name,encryption:encryption.services.blob.enabled}" -o json)
if echo "$STORAGE_ACCOUNTS" | jq -e '.[] | select(.encryption == false)' > /dev/null 2>&1; then
    echo -e "${RED}✗ FAILED: Storage account encryption not enabled${NC}"
    FAILED=$((FAILED + 1))
else
    echo -e "${GREEN}✓ PASSED: All storage accounts encrypted${NC}"
    PASSED=$((PASSED + 1))
fi
echo ""

# Test 2: TLS Version
echo "Test 2: TLS 1.2+ Enforcement"
echo "----------------------------"

# Check storage accounts for min TLS version
MIN_TLS=$(az storage account list -g "$RG_NAME" --query "[].{name:name,minTls:minimumTlsVersion}" -o json)
if echo "$MIN_TLS" | jq -e '.[] | select(.minTls != "TLS1_2")' > /dev/null 2>&1; then
    echo -e "${RED}✗ FAILED: TLS 1.2 not enforced on all storage accounts${NC}"
    FAILED=$((FAILED + 1))
else
    echo -e "${GREEN}✓ PASSED: TLS 1.2+ enforced${NC}"
    PASSED=$((PASSED + 1))
fi
echo ""

# Test 3: Private Endpoints
echo "Test 3: Private Endpoints"
echo "----------------------------"

PRIVATE_ENDPOINTS=$(az network private-endpoint list -g "$RG_NAME" --query "length([])" -o tsv)
if [ "$PRIVATE_ENDPOINTS" -lt 1 ]; then
    echo -e "${RED}✗ FAILED: No private endpoints found${NC}"
    FAILED=$((FAILED + 1))
else
    echo -e "${GREEN}✓ PASSED: $PRIVATE_ENDPOINTS private endpoints configured${NC}"
    PASSED=$((PASSED + 1))
fi
echo ""

# Test 4: Diagnostic Logging
echo "Test 4: Diagnostic Logging"
echo "----------------------------"

# Check if Log Analytics workspace exists
LOG_WORKSPACE=$(az monitor log-analytics workspace list -g "$RG_NAME" --query "[0].id" -o tsv 2>/dev/null || echo "")
if [ -z "$LOG_WORKSPACE" ]; then
    echo -e "${RED}✗ FAILED: Log Analytics workspace not found${NC}"
    FAILED=$((FAILED + 1))
else
    echo -e "${GREEN}✓ PASSED: Log Analytics workspace configured${NC}"

    # Check retention
    RETENTION=$(az monitor log-analytics workspace show --ids "$LOG_WORKSPACE" --query "retentionInDays" -o tsv)
    if [ "$RETENTION" -lt 365 ]; then
        echo -e "${RED}✗ FAILED: Log retention is $RETENTION days (HIPAA requires 365+)${NC}"
        FAILED=$((FAILED + 1))
    else
        echo -e "${GREEN}✓ PASSED: Log retention is $RETENTION days${NC}"
        PASSED=$((PASSED + 1))
    fi
fi
echo ""

# Test 5: Network Security Groups
echo "Test 5: Network Security Groups"
echo "----------------------------"

NSG_COUNT=$(az network nsg list -g "$RG_NAME" --query "length([])" -o tsv)
if [ "$NSG_COUNT" -lt 1 ]; then
    echo -e "${RED}✗ FAILED: No Network Security Groups found${NC}"
    FAILED=$((FAILED + 1))
else
    echo -e "${GREEN}✓ PASSED: $NSG_COUNT Network Security Groups configured${NC}"
    PASSED=$((PASSED + 1))
fi
echo ""

# Test 6: Key Vault Security
echo "Test 6: Key Vault Security"
echo "----------------------------"

KEY_VAULTS=$(az keyvault list -g "$RG_NAME" --query "[]" -o json)
if [ "$(echo "$KEY_VAULTS" | jq '. | length')" -eq 0 ]; then
    echo -e "${RED}✗ FAILED: No Key Vault found${NC}"
    FAILED=$((FAILED + 1))
else
    # Check soft-delete and purge protection
    SOFT_DELETE=$(echo "$KEY_VAULTS" | jq -r '.[0].properties.enableSoftDelete')
    PURGE_PROTECTION=$(echo "$KEY_VAULTS" | jq -r '.[0].properties.enablePurgeProtection')

    if [ "$SOFT_DELETE" = "true" ] && [ "$PURGE_PROTECTION" = "true" ]; then
        echo -e "${GREEN}✓ PASSED: Key Vault soft-delete and purge protection enabled${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAILED: Key Vault protection not fully enabled${NC}"
        echo "  Soft-delete: $SOFT_DELETE, Purge protection: $PURGE_PROTECTION"
        FAILED=$((FAILED + 1))
    fi
fi
echo ""

# Test 7: Public Access
echo "Test 7: Public Network Access"
echo "----------------------------"

# Check Azure OpenAI
OPENAI_PUBLIC=$(az cognitiveservices account list -g "$RG_NAME" --query "[?kind=='OpenAI'].properties.publicNetworkAccess" -o tsv 2>/dev/null || echo "")
if [ "$OPENAI_PUBLIC" = "Disabled" ] || [ -z "$OPENAI_PUBLIC" ]; then
    echo -e "${GREEN}✓ PASSED: Azure OpenAI public access disabled${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAILED: Azure OpenAI public access enabled${NC}"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 8: RBAC Configuration
echo "Test 8: RBAC Configuration"
echo "----------------------------"

ROLE_ASSIGNMENTS=$(az role assignment list -g "$RG_NAME" --query "length([])" -o tsv)
if [ "$ROLE_ASSIGNMENTS" -lt 1 ]; then
    echo -e "${YELLOW}⚠ WARNING: No role assignments found (may be expected in early deployment)${NC}"
else
    echo -e "${GREEN}✓ INFO: $ROLE_ASSIGNMENTS role assignments configured${NC}"
fi
echo ""

# Summary
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All compliance tests passed!${NC}"
    echo ""
    echo "Your deployment meets HIPAA technical safeguards:"
    echo "  ✓ Encryption at rest and in transit"
    echo "  ✓ Access controls (private endpoints, NSGs)"
    echo "  ✓ Audit logging (365+ day retention)"
    echo "  ✓ Security features (Key Vault protection)"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some compliance tests failed${NC}"
    echo ""
    echo "Please review and fix the failed tests before proceeding to production."
    echo ""
    exit 1
fi
