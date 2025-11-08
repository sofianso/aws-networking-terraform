# Quick Start Guide

This guide will help you get up and running quickly with the AWS Networking Terraform infrastructure.

## Prerequisites

Ensure you have the following installed:

```bash
# Check Terraform version
terraform version

# Check Terragrunt version
terragrunt --version

# Check AWS CLI
aws --version

# Verify AWS credentials
aws sts get-caller-identity
```

## Step-by-Step Deployment

### 1. Initial Configuration

```bash
# Clone the repository
git clone https://github.com/your-org/aws-networking-terraform.git
cd aws-networking-terraform

# Copy and configure environment variables
cp .env.example .env
# Edit .env with your account IDs and GitHub details
```

### 2. Create Backend Resources

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://aws-networking-terraform --region ap-southeast-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket aws-networking-terraform \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket aws-networking-terraform \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-2
```

### 3. Update Configuration Files

Update account IDs in the following files:
- `networking/account.hcl`
- `non-prod/account.hcl`
- `prod/account.hcl`

Update GitHub repository in:
- `networking/ap-southeast-2/github-oidc/terragrunt.hcl`

### 4. Deploy Infrastructure

```bash
# Step 1: Deploy GitHub OIDC Role (for CI/CD)
make github-oidc-plan
make github-oidc-apply

# Step 2: Deploy Transit Gateway (Networking Account)
make networking-tgw-plan
make networking-tgw-apply

# Step 3: Deploy Networking VPC
make networking-vpc-plan
make networking-vpc-apply

# Step 4: Deploy Non-Prod VPC
make non-prod-plan
make non-prod-apply

# Step 5: Deploy Prod VPC
make prod-plan
make prod-apply
```

### 5. Verify Deployment

```bash
# Check Transit Gateway
make output ENV=networking COMPONENT=transit-gateway

# Check VPCs
make output ENV=networking COMPONENT=vpc
make output ENV=non-prod COMPONENT=vpc
make output ENV=prod COMPONENT=vpc
```

## Common Operations

### View Help
```bash
make help
```

### Format Code
```bash
make format
```

### Validate Configuration
```bash
make validate-all
```

### Clean Cache
```bash
make clean
```

### View Dependency Graph
```bash
make graph ENV=networking
# This creates dependency-graph.png in the environment directory
```

## Deployment Patterns

### Deploy Everything in an Environment
```bash
cd networking/ap-southeast-2
terragrunt run-all apply
```

### Deploy with Auto-Approve (Caution!)
```bash
make apply-auto ENV=prod COMPONENT=vpc
```

### Check for Drift
```bash
make plan ENV=prod COMPONENT=vpc
```

## Troubleshooting

### State Locked
If you encounter a state lock error:
```bash
cd path/to/locked/component
terragrunt force-unlock <LOCK_ID>
```

### Clean and Reinitialize
```bash
make clean
cd path/to/component
terragrunt init
```

### Debug Mode
```bash
export TG_LOG=debug
make plan ENV=networking COMPONENT=transit-gateway
```

## Next Steps

1. **Configure GitHub Actions**
   - Add `AWS_ACCOUNT_ID` to GitHub repository secrets
   - Test by creating a pull request

2. **Customize Networks**
   - Adjust CIDR blocks in terragrunt.hcl files
   - Modify subnet sizes as needed

3. **Add More Environments**
   - Copy an existing environment directory
   - Update account.hcl and region.hcl
   - Add to Transit Gateway route tables

4. **Monitor Resources**
   - Check VPC Flow Logs in CloudWatch
   - Review Transit Gateway metrics
   - Set up alarms for NAT Gateway usage

## Safety Checklist

Before deploying to production:

- [ ] Reviewed all CIDR blocks for conflicts
- [ ] Verified account IDs are correct
- [ ] Tested in non-prod environment first
- [ ] Backed up existing infrastructure (if any)
- [ ] Reviewed cost estimates
- [ ] Configured monitoring and alerts
- [ ] Documented any customizations
- [ ] Set up proper IAM permissions
- [ ] Enabled MFA for AWS accounts
- [ ] Configured backup and disaster recovery

## Support

For issues or questions:
1. Check the main README.md
2. Review Terragrunt documentation
3. Open a GitHub issue
4. Contact your platform team

---

Happy Terraforming! 🚀
