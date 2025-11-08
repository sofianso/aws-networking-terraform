# AWS Networking Infrastructure with Terragrunt

This repository contains a comprehensive AWS networking infrastructure setup using Terraform and Terragrunt. It implements a hub-and-spoke architecture with Transit Gateway as the central hub, connecting multiple VPCs across different environments.

## 🏗️ Architecture Overview

### High-Level Design

```
```
┌─────────────────────────────────────────────────────────────┐
│                    Networking Account                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │          Transit Gateway (Central Hub)                 │ │
│  │  - Routes traffic between all VPCs                     │ │
│  │  - Separate route tables per environment               │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │          Networking VPC (10.0.0.0/16)                  │ │
│  │  - Multi-AZ (ap-southeast-2a, ap-southeast-2b, ap-southeast-2c) │
│  │  - 3 Public Subnets + 3 Private Subnets                │ │
│  │  - 3 NAT Gateways (High Availability)                  │ │
│  │  - Internet Gateway                                   │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   Non-Prod Account                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │         Non-Prod VPC (10.1.0.0/16)                     │ │
│  │  - Single AZ (ap-southeast-2a) - Cost Optimized        │ │
│  │  - 1 Public Subnet + 1 Private Subnet                  │ │
│  │  - 1 NAT Gateway                                      │ │
│  │  - Internet Gateway                                   │ │
│  │  - Connected to Transit Gateway                       │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      Prod Account                          │
│  ┌────────────────────────────────────────────────────────┐ │
│  │            Prod VPC (10.2.0.0/16)                      │ │
│  │  - Multi-AZ (ap-southeast-2a, ap-southeast-2b, ap-southeast-2c) │
│  │  - 3 Public Subnets + 3 Private Subnets                │ │
│  │  - 3 NAT Gateways (High Availability)                  │ │
│  │  - Internet Gateway                                   │ │
│  │  - Connected to Transit Gateway                       │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```
```

### Key Features

- **Transit Gateway Hub**: Centralized networking hub in the networking account for inter-VPC communication
- **Multi-Environment Setup**: Separate configurations for networking, non-prod, and prod environments
- **High Availability**: Production and networking VPCs use multi-AZ setup with redundant NAT Gateways
- **Cost Optimization**: Non-prod uses single AZ to reduce costs
- **VPC Flow Logs**: Enabled on all VPCs for network traffic monitoring
- **GitHub Actions CI/CD**: Automated Terraform plan on pull requests using OIDC authentication
- **State Management**: Remote state stored in S3 with DynamoDB locking

## 📁 Repository Structure

```
aws-networking-terraform/
├── terragrunt.hcl                    # Root Terragrunt configuration
├── Makefile                          # Build automation
├── README.md                         # This file
│
├── modules/                          # Reusable Terraform modules
│   ├── vpc/                         # VPC module
│   │   ├── main.tf                  # VPC, subnets, IGW, NAT resources
│   │   ├── variables.tf             # Input variables
│   │   └── outputs.tf               # Output values
│   │
│   ├── transit-gateway/             # Transit Gateway module
│   │   ├── main.tf                  # Transit Gateway and route tables
│   │   ├── variables.tf             # Input variables
│   │   └── outputs.tf               # Output values
│   │
│   └── github-oidc/                 # GitHub OIDC IAM role module
│       ├── main.tf                  # OIDC provider and IAM role
│       ├── variables.tf             # Input variables
│       └── outputs.tf               # Output values
│
├── networking/                       # Networking account configurations
│   ├── account.hcl                  # Account-level configuration
│   └── ap-southeast-2/                   # Region-specific resources
│       ├── region.hcl               # Region configuration
│       ├── transit-gateway/         # Transit Gateway deployment
│       │   └── terragrunt.hcl
│       ├── vpc/                     # Networking VPC deployment
│       │   └── terragrunt.hcl
│       └── github-oidc/             # GitHub OIDC role
│           └── terragrunt.hcl
│
├── non-prod/                         # Non-prod account configurations
│   ├── account.hcl                  # Account-level configuration
│   └── ap-southeast-2/                   # Region-specific resources
│       ├── region.hcl               # Region configuration (Single AZ)
│       └── vpc/                     # Non-prod VPC deployment
│           └── terragrunt.hcl
│
├── prod/                             # Production account configurations
│   ├── account.hcl                  # Account-level configuration
│   └── ap-southeast-2/                   # Region-specific resources
│       ├── region.hcl               # Region configuration (Multi-AZ)
│       └── vpc/                     # Production VPC deployment
│           └── terragrunt.hcl
│
└── .github/
    └── workflows/
        └── terraform-plan.yml        # GitHub Actions workflow
```

## 🚀 Getting Started

### Prerequisites

- **Terraform**: >= 1.0
- **Terragrunt**: >= 0.48.0
- **AWS CLI**: Configured with appropriate credentials
- **Make**: For using the Makefile commands

### Installation

1. **Install Terraform**
   ```bash
   brew install terraform
   # or download from https://www.terraform.io/downloads
   ```

2. **Install Terragrunt**
   ```bash
   brew install terragrunt
   # or download from https://github.com/gruntwork-io/terragrunt/releases
   ```

3. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/aws-networking-terraform.git
   cd aws-networking-terraform
   ```

### Initial Setup

1. **Create the S3 bucket for state management** (one-time setup)
   ```bash
   aws s3 mb s3://aws-networking-terraform --region ap-southeast-2
   aws s3api put-bucket-versioning \
     --bucket aws-networking-terraform \
     --versioning-configuration Status=Enabled
   ```

2. **Create DynamoDB table for state locking** (one-time setup)
   ```bash
   aws dynamodb create-table \
     --table-name terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region ap-southeast-2
   ```

3. **Update account IDs**
   - Edit `networking/account.hcl` and set your networking account ID
   - Edit `non-prod/account.hcl` and set your non-prod account ID
   - Edit `prod/account.hcl` and set your prod account ID

4. **Update GitHub repository information**
   - Edit `networking/ap-southeast-2/github-oidc/terragrunt.hcl`
   - Set your GitHub organization and repository name

## 📖 Usage

### Using Make Commands

The Makefile provides convenient shortcuts for common operations:

```bash
# Show all available commands
make help

# Plan for a specific component
make plan ENV=networking REGION=ap-southeast-2 COMPONENT=transit-gateway

# Apply for a specific component
make apply ENV=non-prod REGION=ap-southeast-2 COMPONENT=vpc

# Format all Terraform files
make format

# Plan all components in an environment
make plan-all ENV=prod REGION=ap-southeast-2

# Quick access commands
make networking-tgw-plan      # Plan networking Transit Gateway
make networking-tgw-apply     # Apply networking Transit Gateway
make non-prod-plan            # Plan non-prod VPC
make prod-apply               # Apply prod VPC
```

### Deployment Order

For initial deployment, follow this order:

1. **Deploy GitHub OIDC role** (for CI/CD)
   ```bash
   make github-oidc-apply
   ```

2. **Deploy Transit Gateway** (networking account)
   ```bash
   make networking-tgw-apply
   ```

3. **Deploy Networking VPC** (networking account)
   ```bash
   make networking-vpc-apply
   ```

4. **Deploy Non-Prod VPC**
   ```bash
   make non-prod-apply
   ```

5. **Deploy Prod VPC**
   ```bash
   make prod-apply
   ```

### Manual Terragrunt Commands

You can also use Terragrunt directly:

```bash
# Navigate to a component directory
cd networking/ap-southeast-2/transit-gateway

# Initialize
terragrunt init

# Plan
terragrunt plan

# Apply
terragrunt apply

# Destroy
terragrunt destroy
```

### Running All Components

```bash
# Plan all components in an environment
cd networking/ap-southeast-2
terragrunt run-all plan

# Apply all components in an environment
cd non-prod/ap-southeast-2
terragrunt run-all apply

# Destroy all components in an environment
cd prod/ap-southeast-2
terragrunt run-all destroy
```

## 🔄 CI/CD with GitHub Actions

### Setup

1. **Deploy the GitHub OIDC IAM role**
   ```bash
   make github-oidc-apply
   ```

2. **Add AWS Account ID to GitHub Secrets**
   - Go to your repository settings → Secrets and variables → Actions
   - Add a new secret named `AWS_ACCOUNT_ID` with your AWS account ID

3. **Create a Pull Request**
   - The workflow will automatically run `terraform plan` for changed environments
   - Results will be commented on the PR

### Workflow Features

- ✅ Automatic detection of changed environments
- ✅ Parallel planning for multiple environments
- ✅ Terraform formatting validation
- ✅ Plan results posted as PR comments
- ✅ Secure OIDC authentication (no long-lived credentials)

## 🔒 Security Features

1. **OIDC Authentication**: No AWS credentials stored in GitHub
2. **State Encryption**: S3 backend with encryption enabled
3. **State Locking**: DynamoDB prevents concurrent modifications
4. **VPC Flow Logs**: Network traffic monitoring for all VPCs
5. **Private Subnets**: Resources can be deployed in private subnets with NAT Gateway access
6. **IAM Least Privilege**: GitHub OIDC role has minimal required permissions

## 🌐 Network Configuration

### IP Address Space

| Environment | VPC CIDR      | Public Subnets                           | Private Subnets                          |
|-------------|---------------|------------------------------------------|------------------------------------------|
| Networking  | 10.0.0.0/16   | 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24   | 10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24 |
| Non-Prod    | 10.1.0.0/16   | 10.1.1.0/24                             | 10.1.11.0/24                            |
| Prod        | 10.2.0.0/16   | 10.2.1.0/24, 10.2.2.0/24, 10.2.3.0/24   | 10.2.11.0/24, 10.2.12.0/24, 10.2.13.0/24 |

### Availability Zones

- **Networking**: Multi-AZ (ap-southeast-2a, ap-southeast-2b, ap-southeast-2c)
- **Non-Prod**: Single AZ (ap-southeast-2a) - Cost optimized
- **Prod**: Multi-AZ (ap-southeast-2a, ap-southeast-2b, ap-southeast-2c) - High availability

## 🛠️ Customization

### Adding a New Environment

1. Create a new directory (e.g., `staging/`)
2. Add `account.hcl` with account configuration
3. Create region directory with `region.hcl`
4. Add component directories with `terragrunt.hcl` files
5. Update the Transit Gateway route table in the networking account

### Changing Regions

1. Update `region.hcl` in the environment directory
2. Update availability zones list
3. Adjust CIDR blocks if needed

### Modifying Subnet Configuration

Edit the terragrunt.hcl file for the VPC:
```hcl
inputs = {
  vpc_cidr             = "10.3.0.0/16"
  public_subnet_cidrs  = ["10.3.1.0/24", "10.3.2.0/24"]
  private_subnet_cidrs = ["10.3.11.0/24", "10.3.12.0/24"]
}
```

## 📊 Outputs

After deployment, you can view outputs:

```bash
# View outputs for a specific component
make output ENV=networking COMPONENT=transit-gateway

# View all outputs for an environment
make output-all ENV=prod
```

Common outputs include:
- VPC IDs
- Subnet IDs
- Transit Gateway ID
- NAT Gateway IDs
- Route table IDs

## 🧹 Cleanup

To destroy all resources:

```bash
# Destroy in reverse order
make destroy ENV=prod COMPONENT=vpc
make destroy ENV=non-prod COMPONENT=vpc
make destroy ENV=networking COMPONENT=vpc
make destroy ENV=networking COMPONENT=transit-gateway
make destroy ENV=networking COMPONENT=github-oidc

# Clean local cache
make clean
```

## 🔍 Troubleshooting

### Common Issues

1. **State lock errors**
   ```bash
   # Force unlock (use with caution)
   cd path/to/component
   terragrunt force-unlock LOCK_ID
   ```

2. **Dependency errors**
   - Ensure Transit Gateway is deployed before VPCs
   - Check that cross-account permissions are configured

3. **GitHub Actions failing**
   - Verify AWS_ACCOUNT_ID secret is set
   - Check that OIDC role has necessary permissions
   - Ensure role trust policy allows your repository

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS Transit Gateway Documentation](https://docs.aws.amazon.com/vpc/latest/tgw/)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `make format` to format code
5. Submit a pull request

## 📧 Support

For issues and questions, please open a GitHub issue in this repository.

---

**Note**: Remember to replace placeholder values (account IDs, GitHub organization, etc.) with your actual values before deployment.
