# AWS Networking Infrastructure - Documentation Index

Welcome to the AWS Networking Infrastructure documentation! This guide will help you navigate through all available documentation.

## 📚 Documentation Structure

### 🚀 Getting Started
Start here if you're new to this project:

1. **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** ⭐ **Start Here!**
   - Overview of what has been created
   - Complete file structure
   - Key features implemented
   - Quick start commands
   - Configuration checklist

2. **[QUICKSTART.md](QUICKSTART.md)**
   - Step-by-step deployment guide
   - Initial configuration
   - Backend resource creation
   - Common operations
   - Troubleshooting basics

3. **[README.md](README.md)**
   - Comprehensive project documentation
   - Architecture overview
   - Repository structure
   - Usage instructions
   - Security features
   - Customization guide

### 🏗️ Architecture & Design

4. **[ARCHITECTURE.md](ARCHITECTURE.md)**
   - Architecture Decision Records (ADRs)
   - Design rationale
   - Trade-offs and considerations
   - Future considerations

5. **[DIAGRAMS.md](DIAGRAMS.md)**
   - Visual network diagrams
   - Traffic flow diagrams
   - Subnet layouts
   - Component dependencies
   - Route table configurations
   - Monitoring architecture

### 🔧 Operations & Maintenance

6. **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**
   - Common issues and solutions
   - State lock problems
   - Terragrunt errors
   - AWS permissions issues
   - GitHub Actions debugging
   - Networking problems
   - Debug mode instructions

### 📝 Reference Files

7. **[Makefile](Makefile)**
   - Build automation
   - Common command shortcuts
   - Environment-specific targets
   - Formatting and validation

8. **[.gitignore](.gitignore)**
   - Git ignore patterns
   - Terraform and Terragrunt cache
   - Sensitive files

9. **[.env.example](.env.example)**
   - Environment variables template
   - Configuration examples

10. **[.pre-commit-config.yaml](.pre-commit-config.yaml)**
    - Pre-commit hooks configuration
    - Code quality checks

## 📖 Quick Navigation Guide

### By Task

#### "I'm deploying for the first time"
1. Read [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Overview
2. Follow [QUICKSTART.md](QUICKSTART.md) - Step-by-step
3. Reference [README.md](README.md) - Detailed instructions

#### "I need to understand the architecture"
1. Check [DIAGRAMS.md](DIAGRAMS.md) - Visual overview
2. Read [ARCHITECTURE.md](ARCHITECTURE.md) - Design decisions
3. Review [README.md](README.md) - Architecture section

#### "Something is broken"
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
2. Review [README.md](README.md) - Troubleshooting section
3. Check [QUICKSTART.md](QUICKSTART.md) - Verification steps

#### "I want to customize the setup"
1. Read [README.md](README.md) - Customization section
2. Check [ARCHITECTURE.md](ARCHITECTURE.md) - Design considerations
3. Review module files in `modules/` directory

#### "I need to use Make commands"
1. Run `make help` - See all available commands
2. Check [Makefile](Makefile) - Command definitions
3. Reference [README.md](README.md) - Usage examples

### By Role

#### DevOps Engineer
**Essential reading:**
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
- [QUICKSTART.md](QUICKSTART.md)
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- [Makefile](Makefile)

**Reference:**
- [README.md](README.md)
- [DIAGRAMS.md](DIAGRAMS.md)

#### Solutions Architect
**Essential reading:**
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [DIAGRAMS.md](DIAGRAMS.md)
- [README.md](README.md) - Architecture section

**Reference:**
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
- Module source code in `modules/`

#### Security Engineer
**Essential reading:**
- [README.md](README.md) - Security section
- [ARCHITECTURE.md](ARCHITECTURE.md) - ADR-004, ADR-006
- Module IAM configurations

**Reference:**
- [DIAGRAMS.md](DIAGRAMS.md) - Security flows
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Permissions

#### Developer (New to project)
**Start here:**
1. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
2. [QUICKSTART.md](QUICKSTART.md)
3. [README.md](README.md)
4. `make help`

## 📂 Code Structure Reference

### Terraform Modules
Located in `modules/` directory:

- **[modules/vpc/](modules/vpc/)** - VPC, subnets, NAT, IGW
  - `main.tf` - Main resources
  - `variables.tf` - Input variables
  - `outputs.tf` - Output values

- **[modules/transit-gateway/](modules/transit-gateway/)** - Transit Gateway hub
  - `main.tf` - TGW and route tables
  - `variables.tf` - Input variables
  - `outputs.tf` - Output values

- **[modules/github-oidc/](modules/github-oidc/)** - GitHub OIDC authentication
  - `main.tf` - OIDC provider and IAM role
  - `variables.tf` - Input variables
  - `outputs.tf` - Output values

### Environment Configurations
Located in environment directories:

- **[networking/](networking/)** - Networking account
  - `account.hcl` - Account configuration
  - `ap-southeast-2/region.hcl` - Region configuration
  - `ap-southeast-2/transit-gateway/terragrunt.hcl` - TGW config
  - `ap-southeast-2/vpc/terragrunt.hcl` - VPC config
  - `ap-southeast-2/github-oidc/terragrunt.hcl` - OIDC config

- **[non-prod/](non-prod/)** - Non-prod account (Single AZ)
  - `account.hcl` - Account configuration
  - `ap-southeast-2/region.hcl` - Region configuration (Single AZ)
  - `ap-southeast-2/vpc/terragrunt.hcl` - VPC config

- **[prod/](prod/)** - Production account (Multi-AZ)
  - `account.hcl` - Account configuration
  - `ap-southeast-2/region.hcl` - Region configuration (Multi-AZ)
  - `ap-southeast-2/vpc/terragrunt.hcl` - VPC config

### CI/CD Configuration
- **[.github/workflows/terraform-plan.yml](.github/workflows/terraform-plan.yml)**
  - GitHub Actions workflow
  - Terraform plan on PR
  - OIDC authentication

## 🔍 Search Guide

### Find Information About...

| Topic | Document | Section |
|-------|----------|---------|
| Initial setup | QUICKSTART.md | Step-by-Step Deployment |
| Architecture overview | README.md | Architecture Overview |
| Network diagrams | DIAGRAMS.md | All sections |
| Make commands | Makefile | Run `make help` |
| State locks | TROUBLESHOOTING.md | State Lock Issues |
| OIDC setup | README.md | CI/CD with GitHub Actions |
| Cost optimization | README.md | Cost Considerations |
| Security features | README.md | Security Features |
| Subnet layout | DIAGRAMS.md | Subnet Layout |
| Transit Gateway | ARCHITECTURE.md | ADR-002 |
| Multi-AZ setup | ARCHITECTURE.md | ADR-003 |
| VPC Flow Logs | ARCHITECTURE.md | ADR-006 |
| Terragrunt errors | TROUBLESHOOTING.md | Terragrunt Errors |
| AWS permissions | TROUBLESHOOTING.md | AWS Permissions |
| GitHub Actions | TROUBLESHOOTING.md | GitHub Actions Issues |
| Customization | README.md | Customization |

## 📋 Cheat Sheets

### Common Commands
```bash
# View all Make commands
make help

# Deploy sequence
make github-oidc-apply
make networking-tgw-apply
make networking-vpc-apply
make non-prod-apply
make prod-apply

# Format code
make format

# Clean cache
make clean

# View outputs
make output ENV=networking COMPONENT=vpc
```

### File Locations
```bash
# Root configuration
./terragrunt.hcl

# VPC module
./modules/vpc/

# Networking configs
./networking/ap-southeast-2/

# Documentation
./README.md
./QUICKSTART.md
./TROUBLESHOOTING.md
```

### Key Concepts
- **Terragrunt**: Wrapper for Terraform (DRY configurations)
- **Transit Gateway**: Central networking hub
- **Multi-AZ**: High availability (Prod, Networking)
- **Single AZ**: Cost optimization (Non-Prod)
- **OIDC**: Secure GitHub Actions authentication
- **Remote State**: S3 + DynamoDB locking

## 🆘 Getting Help

### Self-Service
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review [QUICKSTART.md](QUICKSTART.md)
3. Search documentation (Ctrl+F / Cmd+F)
4. Run `make help`

### Support Channels
1. Review existing documentation
2. Check GitHub Issues
3. Review AWS documentation
4. Open new GitHub Issue (include debug logs)

## 📚 External Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

## 🔄 Document Updates

This index is current as of the initial project creation. For the most up-to-date information:
- Check the main [README.md](README.md)
- Review recent commits
- Check for new documentation files

---

**Quick Links:**
- 🚀 [Start Here - Project Summary](PROJECT_SUMMARY.md)
- 📖 [Quick Start Guide](QUICKSTART.md)
- 📚 [Full Documentation](README.md)
- 🏗️ [Architecture Diagrams](DIAGRAMS.md)
- 🔧 [Troubleshooting](TROUBLESHOOTING.md)
- 🎯 [Make Commands](Makefile) - Run `make help`

---

*Happy Infrastructure Coding! 🚀*
