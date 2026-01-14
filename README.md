# Upstate AI Healthcare Portal

A production-ready, HIPAA-compliant Azure AI Healthcare Portal using Microsoft's GenAI Gateway pattern with Azure API Management (APIM) and LiteLLM proxy architecture.

## Architecture Overview

- **AI Gateway**: Azure API Management Premium v2
- **Model Router**: LiteLLM Proxy (multi-model support)
- **AI Models**: Azure OpenAI (GPT-4o, GPT-4 Turbo) + Optional external models (Anthropic Claude, Google Gemini)
- **Frontend**: Next.js with Azure AD authentication
- **Infrastructure**: Azure-native with Terraform IaC
- **Compliance**: HIPAA-eligible with Microsoft BAA

## Technology Stack

### Infrastructure
- Terraform for Infrastructure-as-Code
- Azure VNet with private endpoints
- Azure Container Apps for microservices
- Azure Static Web Apps for frontend

### Core Services
- Azure API Management Premium v2
- Azure OpenAI Service
- Azure PostgreSQL Flexible Server
- Azure Redis Cache Premium
- Azure Key Vault
- Azure Monitor + Log Analytics

### Application
- Next.js 14+ (TypeScript)
- MSAL React for authentication
- FastAPI for RAG backend (optional)

## Project Structure

```
d:\AI_HealthCare\Upstate_AI_portal\
├── infrastructure/          # Terraform infrastructure code
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── modules/        # Reusable Terraform modules
│   │   └── environments/   # Environment-specific configs
│   └── scripts/           # Deployment and utility scripts
├── litellm/               # LiteLLM proxy configuration
│   ├── config.yaml
│   └── Dockerfile
├── frontend/              # Next.js frontend application
│   ├── src/
│   └── package.json
├── backend/               # Optional RAG service (FastAPI)
│   ├── src/
│   └── requirements.txt
├── tests/                 # Integration and compliance tests
│   ├── integration/
│   └── compliance/
└── docs/                  # Documentation
    ├── deployment/
    └── user-guides/
```

## Getting Started

### Prerequisites

- Azure subscription with HIPAA BAA signed
- Terraform >= 1.6.0
- Azure CLI >= 2.50.0
- Node.js >= 18.x (for frontend)
- Python >= 3.11 (for backend)
- Docker (for local development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Upstate_AI_portal
   ```

2. **Initialize Terraform backend**
   ```bash
   cd infrastructure/scripts
   ./init-terraform.sh
   ```

3. **Deploy infrastructure**
   ```bash
   ./deploy.sh dev
   ```

4. **Deploy frontend**
   ```bash
   cd ../../frontend
   npm install
   npm run build
   # Deploy to Azure Static Web Apps via GitHub Actions
   ```

## User Roles

The portal supports four user roles with distinct permissions:

1. **Clinician**: Clinical AI tools, SOAP notes, differential diagnosis
2. **Billing Staff**: Medical coding, ICD-10/CPT lookup, prior authorization
3. **Admin**: User management, system monitoring, analytics
4. **Developer**: API testing, model selection, integration development

## HIPAA Compliance

This solution implements the following HIPAA safeguards:

- ✅ Encryption at rest (AES-256)
- ✅ Encryption in transit (TLS 1.2+)
- ✅ Private endpoints for all PaaS services
- ✅ Azure AD MFA enforcement
- ✅ Comprehensive audit logging (365-day retention)
- ✅ PHI detection and masking
- ✅ Role-based access control (RBAC)

## Cost Estimate

Production environment: **$5,000-6,000/month**

See [cost breakdown](docs/deployment/cost-estimate.md) for details.

## Documentation

- [Deployment Guide](docs/deployment/deployment-guide.md)
- [Disaster Recovery Plan](docs/deployment/disaster-recovery.md)
- [Clinician User Guide](docs/user-guides/clinician-guide.md)
- [Admin User Guide](docs/user-guides/admin-guide.md)
- [HIPAA Compliance](docs/compliance/hipaa-controls.md)

## Support

- Email: ai-portal-support@upstate.com
- Documentation: See [docs/](docs/) directory
- Issues: GitHub Issues

## License

Proprietary - Upstate Healthcare

## Security

Please report security vulnerabilities to security@upstate.com
