# Troubleshooting Guide

Common issues and their solutions when working with this AWS networking infrastructure.

## Table of Contents
- [State Lock Issues](#state-lock-issues)
- [Terragrunt Errors](#terragrunt-errors)
- [AWS Permissions](#aws-permissions)
- [GitHub Actions Issues](#github-actions-issues)
- [Networking Issues](#networking-issues)
- [Cost Concerns](#cost-concerns)

---

## State Lock Issues

### Problem: State file is locked
```
Error: Error acquiring the state lock
Lock Info:
  ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Path: aws-networking-terraform/...
  Operation: OperationTypePlan
  Who: user@host
  Version: 1.6.0
  Created: 2025-11-08 12:34:56.789012345 +0000 UTC
```

**Solution:**
```bash
# 1. Verify no one else is running terraform
# 2. Force unlock (use with caution!)
cd path/to/locked/component
terragrunt force-unlock LOCK_ID

# Replace LOCK_ID with the ID from the error message
```

**Prevention:**
- Always ensure previous operations complete
- Don't interrupt `terraform apply` or `plan` operations
- Use `make clean` if you have stale locks

---

## Terragrunt Errors

### Problem: Module not found
```
Error: Module not found: ../../../modules/vpc
```

**Solution:**
```bash
# Ensure you're running from the correct directory
cd path/to/environment/region/component

# Verify the relative path is correct
ls ../../../modules/vpc
```

### Problem: Dependency cycle detected
```
Error: Cycle detected in dependencies
```

**Solution:**
```bash
# 1. Check your terragrunt.hcl for circular dependencies
# 2. Deploy components in correct order:
make networking-tgw-apply    # First
make networking-vpc-apply    # Second
make non-prod-apply          # Third
make prod-apply              # Fourth
```

### Problem: Failed to initialize backend
```
Error: Failed to get existing workspaces: S3 bucket does not exist
```

**Solution:**
```bash
# Create the S3 bucket
aws s3 mb s3://aws-networking-terraform --region ap-southeast-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket aws-networking-terraform \
  --versioning-configuration Status=Enabled

# Create DynamoDB table
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-2
```

---

## AWS Permissions

### Problem: Access Denied when creating resources
```
Error: creating EC2 VPC: UnauthorizedOperation
```

**Solution:**
```bash
# 1. Verify your AWS credentials
aws sts get-caller-identity

# 2. Check you have the necessary permissions
# Required permissions include:
# - ec2:*
# - iam:CreateRole, iam:PutRolePolicy, etc.
# - logs:CreateLogGroup, etc.
# - s3:ListBucket, s3:GetObject, s3:PutObject
# - dynamodb:GetItem, dynamodb:PutItem

# 3. If using assumed role, verify trust policy
aws sts assume-role --role-arn <ROLE_ARN> --role-session-name test
```

### Problem: Cross-account Transit Gateway attachment fails
```
Error: creating EC2 Transit Gateway VPC Attachment: UnauthorizedOperation
```

**Solution:**
```bash
# 1. Ensure Transit Gateway is shared with the account via RAM (Resource Access Manager)
# OR
# 2. Deploy Transit Gateway in the same account
# OR
# 3. Update Transit Gateway to auto-accept attachments
#    Set in modules/transit-gateway/variables.tf:
#    enable_auto_accept_shared_attachments = true
```

---

## GitHub Actions Issues

### Problem: OIDC role assumption fails
```
Error: Failed to assume role via OIDC
```

**Solution:**
```bash
# 1. Verify the OIDC role exists
aws iam get-role --role-name github-oidc-role

# 2. Check the trust policy allows your repository
aws iam get-role --role-name github-oidc-role --query 'Role.AssumeRolePolicyDocument'

# 3. Verify GitHub secret is set
# Go to: GitHub Repo → Settings → Secrets → AWS_ACCOUNT_ID

# 4. Update the trust policy if needed
# Edit: networking/ap-southeast-2/github-oidc/terragrunt.hcl
# Ensure github_org and github_repo are correct
```

### Problem: Workflow doesn't trigger on PR
```
No workflow runs appear when creating a pull request
```

**Solution:**
```yaml
# 1. Check the workflow file exists
ls .github/workflows/terraform-plan.yml

# 2. Verify the trigger paths
# Edit .github/workflows/terraform-plan.yml
on:
  pull_request:
    paths:
      - '**.tf'
      - '**.hcl'
      
# 3. Ensure you changed .tf or .hcl files in your PR

# 4. Check GitHub Actions is enabled
# Go to: GitHub Repo → Settings → Actions → General
```

### Problem: Plan output too large for PR comment
```
Error: Comment body is too large
```

**Solution:**
```yaml
# Modify .github/workflows/terraform-plan.yml to truncate output
# Add this to the plan step:
run: |
  terragrunt run-all plan --terragrunt-non-interactive | head -n 1000
```

---

## Networking Issues

### Problem: Can't reach internet from private subnet
```
Instances in private subnet can't access internet
```

**Solution:**
```bash
# 1. Verify NAT Gateway exists
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=<VPC_ID>"

# 2. Check NAT Gateway state is "available"

# 3. Verify route table has route to NAT Gateway
aws ec2 describe-route-tables --filter "Name=vpc-id,Values=<VPC_ID>"
# Look for: 0.0.0.0/0 → nat-xxxxx

# 4. Check security groups allow outbound traffic

# 5. Verify NACL rules allow traffic
```

### Problem: VPC peering through Transit Gateway not working
```
Can't reach resources in other VPCs
```

**Solution:**
```bash
# 1. Verify Transit Gateway attachments are in "available" state
aws ec2 describe-transit-gateway-attachments

# 2. Check route tables have routes through TGW
# Private subnet route table should have:
# 10.0.0.0/8 → tgw-xxxxx

# 3. Verify Transit Gateway route table associations
aws ec2 describe-transit-gateway-route-tables

# 4. Check security groups allow cross-VPC traffic

# 5. Add routes if missing:
# Edit terragrunt.hcl and add routes to private route tables
```

### Problem: VPC Flow Logs not appearing
```
No flow log data in CloudWatch
```

**Solution:**
```bash
# 1. Verify Flow Logs are enabled
aws ec2 describe-flow-logs --filter "Name=resource-id,Values=<VPC_ID>"

# 2. Check IAM role has correct permissions
aws iam get-role --role-name <FLOW_LOG_ROLE_NAME>

# 3. Verify CloudWatch Log Group exists
aws logs describe-log-groups --log-group-name-prefix "/aws/vpc/"

# 4. Wait 10-15 minutes for logs to appear (there's a delay)

# 5. Generate some traffic to see logs
```

---

## Cost Concerns

### Problem: Unexpected high costs
```
AWS bill is higher than expected
```

**Investigation:**
```bash
# 1. Check NAT Gateway usage
# Each NAT Gateway costs ~$32/month + data processing

# 2. Review Transit Gateway costs
# ~$36/month + $0.02/GB data processing

# 3. Check CloudWatch Logs storage
aws logs describe-log-groups --query 'logGroups[*].[logGroupName,storedBytes]'

# 4. Review VPC Flow Logs volume
```

**Cost Optimization:**
```bash
# For Non-Prod: Already using single AZ and single NAT

# For Prod: Consider these options
# 1. VPC Endpoints for AWS services (reduce NAT data charges)
# 2. Adjust CloudWatch retention
# 3. Filter VPC Flow Logs (only log rejected traffic)

# Update modules/vpc/main.tf:
resource "aws_flow_log" "main" {
  traffic_type = "REJECT"  # Instead of "ALL"
  # ... rest of config
}
```

---

## Dependency Issues

### Problem: VPC can't find Transit Gateway
```
Error: Invalid value for transit_gateway_id
```

**Solution:**
```bash
# 1. Ensure Transit Gateway is deployed first
cd networking/ap-southeast-2/transit-gateway
terragrunt apply

# 2. Check the dependency block in VPC terragrunt.hcl
dependency "transit_gateway" {
  config_path = "../transit-gateway"
  # Path should be correct relative path
}

# 3. Verify outputs exist
cd networking/ap-southeast-2/transit-gateway
terragrunt output

# 4. Try with mock outputs disabled
skip_outputs = false  # In dependency block
```

---

## Formatting Issues

### Problem: Terraform formatting check fails in CI
```
Error: Terraform files are not formatted correctly
```

**Solution:**
```bash
# Format all files
make format

# Check which files need formatting
terraform fmt -check -recursive .

# Commit the formatted files
git add .
git commit -m "Format Terraform files"
git push
```

---

## Debug Mode

### Enable detailed logging

```bash
# Terragrunt debug mode
export TG_LOG=debug
export TERRAGRUNT_LOG_LEVEL=debug

# Terraform debug mode
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Run your command
make plan ENV=networking COMPONENT=vpc

# Review logs
cat terraform.log
```

---

## Common Commands for Debugging

```bash
# Check AWS credentials and account
aws sts get-caller-identity

# List S3 buckets
aws s3 ls

# Verify S3 bucket exists
aws s3 ls s3://aws-networking-terraform

# Check DynamoDB table
aws dynamodb describe-table --table-name terraform-locks

# List VPCs
aws ec2 describe-vpcs

# List Transit Gateways
aws ec2 describe-transit-gateways

# Check NAT Gateways
aws ec2 describe-nat-gateways

# View CloudWatch Log Groups
aws logs describe-log-groups

# Terragrunt validate
cd path/to/component
terragrunt validate

# Terraform validate (after init)
cd path/to/component
terragrunt init
terragrunt validate

# Check Terragrunt version
terragrunt --version

# Check Terraform version
terraform version
```

---

## Getting Help

### Before Opening an Issue

1. **Check the logs**
   ```bash
   export TG_LOG=debug
   make plan ENV=networking COMPONENT=vpc 2>&1 | tee debug.log
   ```

2. **Verify prerequisites**
   - [ ] Terraform >= 1.0
   - [ ] Terragrunt >= 0.48.0
   - [ ] AWS CLI configured
   - [ ] S3 bucket exists
   - [ ] DynamoDB table exists

3. **Clean and retry**
   ```bash
   make clean
   cd path/to/component
   terragrunt init
   terragrunt plan
   ```

4. **Check for known issues**
   - Review this troubleshooting guide
   - Check GitHub issues
   - Review AWS service health dashboard

### Opening an Issue

Include:
- [ ] Full error message
- [ ] Terragrunt version
- [ ] Terraform version
- [ ] Command that caused the error
- [ ] Debug logs (with sensitive data removed)
- [ ] Steps to reproduce

---

## Quick Reference

### Clean Everything
```bash
make clean
find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name ".terragrunt-cache" -type d -exec rm -rf {} + 2>/dev/null || true
```

### Reinitialize All
```bash
cd networking/ap-southeast-2
terragrunt run-all init --terragrunt-non-interactive
```

### Check State
```bash
cd path/to/component
terragrunt state list
terragrunt state show <RESOURCE_NAME>
```

### Import Existing Resources
```bash
cd path/to/component
terragrunt import <RESOURCE_TYPE>.<NAME> <RESOURCE_ID>

# Example:
terragrunt import aws_vpc.main vpc-1234567890abcdef0
```

---

**Remember**: Always test changes in non-prod before applying to production! 🛡️
