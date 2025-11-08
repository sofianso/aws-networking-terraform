# GitHub Actions Workflows Guide

This document explains the CI/CD workflows configured for this project.

## Overview

The project uses three GitHub Actions workflows to manage infrastructure deployment:

1. **Terraform Plan** - Runs on Pull Requests
2. **Deploy to Production** - Runs when code is merged to `main`
3. **Deploy to Non-Production** - Runs when code is merged to `develop`

## Workflow Details

### 1. Terraform Plan (`terraform-plan.yml`)

**Trigger:** Pull Request to `main` or `develop` branches

**Purpose:** Validates and plans infrastructure changes before deployment

**Steps:**
- Detects which environments have changed files
- Runs `terragrunt init`, `validate`, and `plan` for affected environments
- Comments the plan output on the Pull Request
- Helps reviewers understand infrastructure changes

**Permissions Required:**
- `id-token: write` - For OIDC authentication
- `contents: read` - To checkout code
- `pull-requests: write` - To comment on PRs

---

### 2. Deploy to Production (`deploy-prod.yml`)

**Trigger:** Push to `main` branch (typically after PR merge)

**Purpose:** Deploys infrastructure changes to the production environment

**Deployment Order:**
1. **Deploy Networking Infrastructure** (Transit Gateway, Networking VPC)
2. **Deploy Production VPC** (Multi-AZ production environment)

**Steps per Job:**
- Checkout code
- Setup Terraform and Terragrunt
- Configure AWS credentials using OIDC
- Initialize Terragrunt
- Plan infrastructure changes
- Apply changes with auto-approval
- Create deployment summary

**On Failure:**
- Automatically creates a GitHub issue with failure details
- Tags issue with `deployment-failure`, `production`, `critical`

---

### 3. Deploy to Non-Production (`deploy-non-prod.yml`)

**Trigger:** Push to `develop` branch (typically after PR merge)

**Purpose:** Deploys infrastructure changes to the non-production environment

**Deployment Order:**
1. **Deploy Networking Infrastructure** (Transit Gateway, Networking VPC)
2. **Deploy Non-Production VPC** (Single-AZ non-prod environment)

**Steps per Job:**
- Checkout code
- Setup Terraform and Terragrunt
- Configure AWS credentials using OIDC
- Initialize Terragrunt
- Plan infrastructure changes
- Apply changes with auto-approval
- Create deployment summary

**On Failure:**
- Automatically creates a GitHub issue with failure details
- Tags issue with `deployment-failure`, `non-prod`

---

## Required GitHub Secrets

You must configure the following secrets in your GitHub repository:

### Repository Secrets

Go to: **Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Description | Example Value |
|------------|-------------|---------------|
| `AWS_ACCOUNT_ID_NETWORKING` | AWS Account ID for networking account | `123456789012` |
| `AWS_ACCOUNT_ID_PROD` | AWS Account ID for production account | `345678901234` |
| `AWS_ACCOUNT_ID_NON_PROD` | AWS Account ID for non-prod account | `234567890123` |

### How to Set Secrets

```bash
# Using GitHub CLI
gh secret set AWS_ACCOUNT_ID_NETWORKING --body "123456789012"
gh secret set AWS_ACCOUNT_ID_PROD --body "345678901234"
gh secret set AWS_ACCOUNT_ID_NON_PROD --body "234567890123"
```

Or via GitHub UI:
1. Go to your repository
2. Click **Settings**
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Enter the name and value
6. Click **Add secret**

---

## Branching Strategy

The workflows follow this branching strategy:

```
┌─────────────┐
│   develop   │  ←── Feature branches merge here
└──────┬──────┘
       │
       │ (Triggers non-prod deployment)
       │
       ▼
┌─────────────┐
│  Non-Prod   │  Single-AZ, cost-optimized
│     VPC     │
└─────────────┘

       │
       │ (After testing, merge develop → main)
       │
       ▼
┌─────────────┐
│     main    │  ←── Release branch
└──────┬──────┘
       │
       │ (Triggers prod deployment)
       │
       ▼
┌─────────────┐
│  Production │  Multi-AZ, high availability
│     VPC     │
└─────────────┘
```

### Workflow Process

1. **Development:**
   ```bash
   # Create feature branch from develop
   git checkout develop
   git checkout -b feature/new-vpc-config
   
   # Make changes and commit
   git add .
   git commit -m "Add new VPC configuration"
   
   # Push and create PR to develop
   git push origin feature/new-vpc-config
   ```

2. **Pull Request to Develop:**
   - Opens PR from `feature/new-vpc-config` → `develop`
   - Terraform Plan workflow runs automatically
   - Review plan output in PR comments
   - Merge PR when approved

3. **Non-Prod Deployment:**
   - PR merge triggers `deploy-non-prod.yml`
   - Deploys to non-production environment
   - Test changes in non-prod

4. **Promote to Production:**
   ```bash
   # Create PR from develop to main
   git checkout main
   git pull origin main
   git checkout -b release/v1.0.0
   git merge develop
   git push origin release/v1.0.0
   ```

5. **Pull Request to Main:**
   - Opens PR from `release/v1.0.0` → `main`
   - Terraform Plan workflow runs again
   - Review plan for production
   - Merge PR when approved

6. **Production Deployment:**
   - PR merge triggers `deploy-prod.yml`
   - Deploys to production environment

---

## AWS OIDC Setup

Before the workflows can run, you must set up OIDC authentication in AWS:

### 1. Create OIDC Provider (one per AWS account)

```bash
# Navigate to the github-oidc module
cd networking/ap-southeast-2/github-oidc

# Update terragrunt.hcl with your GitHub org and repo
# Then apply
terragrunt init
terragrunt apply
```

### 2. Create IAM Role in Each Account

The role must be named `github-oidc-role` (or update workflow files if using a different name).

Required trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main",
            "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/develop",
            "repo:YOUR_ORG/YOUR_REPO:pull_request"
          ]
        }
      }
    }
  ]
}
```

### 3. Attach Required Permissions

The role needs permissions for:
- EC2 (VPC, Subnets, Transit Gateway, etc.)
- IAM (for managing roles)
- CloudWatch Logs
- S3 (for state backend)
- DynamoDB (for state locking)

See `modules/github-oidc/main.tf` for the complete policy.

---

## Environment Variables

Each workflow uses these environment variables:

| Variable | Value | Description |
|----------|-------|-------------|
| `AWS_REGION` | `ap-southeast-2` | AWS region for deployments |
| `TERRAGRUNT_VERSION` | `0.54.0` | Terragrunt version |
| `TERRAFORM_VERSION` | `1.6.0` | Terraform version |
| `ENVIRONMENT` | `prod` or `non-prod` | Environment being deployed |

---

## Monitoring Deployments

### View Workflow Runs

1. Go to your GitHub repository
2. Click the **Actions** tab
3. Select a workflow from the left sidebar
4. Click on a specific run to see details

### Deployment Summary

Each deployment creates a summary showing:
- Environment deployed
- AWS region
- Branch name
- Commit SHA
- Actor who triggered the deployment

### Failure Notifications

When a deployment fails:
- An issue is automatically created in the repository
- The issue includes:
  - Workflow name and run ID
  - Commit SHA and actor
  - Link to failed workflow
  - Appropriate labels for filtering

---

## Manual Deployment

If you need to manually trigger a deployment:

### Option 1: Add workflow_dispatch

Add this to the workflow file:

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:  # Allows manual trigger
```

### Option 2: Empty Commit

```bash
# Trigger prod deployment
git checkout main
git commit --allow-empty -m "Trigger deployment"
git push origin main

# Trigger non-prod deployment
git checkout develop
git commit --allow-empty -m "Trigger deployment"
git push origin develop
```

---

## Troubleshooting

### Workflow Not Triggering

**Issue:** Workflow doesn't run when PR is created or code is merged

**Solutions:**
1. Check that the changed files match the `paths:` filter
2. Verify branch names match (`main`, `develop`)
3. Ensure workflow file syntax is correct

### OIDC Authentication Failed

**Issue:** `Error: Could not assume role`

**Solutions:**
1. Verify GitHub secrets are set correctly
2. Check OIDC provider exists in AWS account
3. Verify IAM role trust policy includes your repo
4. Ensure role name matches workflow configuration

### Terragrunt Init Failed

**Issue:** `Error: Failed to initialize`

**Solutions:**
1. Verify S3 bucket `aws-networking-terraform` exists
2. Check DynamoDB table `terraform-locks` exists
3. Ensure IAM role has S3 and DynamoDB permissions
4. Verify region is correct in terragrunt.hcl

### Plan Shows Unexpected Changes

**Issue:** Terraform plan shows resources being recreated

**Solutions:**
1. Check for configuration drift
2. Verify no manual changes were made in AWS console
3. Review state file for inconsistencies
4. Consider running `terragrunt refresh`

---

## Best Practices

### 1. Always Review Plans
- Never merge a PR without reviewing the Terraform plan
- Understand what resources will be created/modified/destroyed
- Check for unexpected changes

### 2. Test in Non-Prod First
- Always merge to `develop` and test in non-prod
- Verify infrastructure works as expected
- Only promote to `main` after validation

### 3. Use Protected Branches
```bash
# Require PR reviews for main and develop
Settings → Branches → Add rule

Branch name pattern: main
☑ Require pull request reviews before merging
☑ Require status checks to pass before merging
  - terraform-plan

Branch name pattern: develop
☑ Require pull request reviews before merging
☑ Require status checks to pass before merging
  - terraform-plan
```

### 4. Rotate Credentials Regularly
- AWS OIDC uses temporary credentials (secure)
- Review IAM role permissions quarterly
- Audit CloudTrail logs for unusual activity

### 5. Monitor Costs
- Production uses multi-AZ (higher cost)
- Non-prod uses single-AZ (cost-optimized)
- Review AWS Cost Explorer monthly
- Set up billing alerts

---

## Advanced Configuration

### Adding New Environments

To add a new environment (e.g., `staging`):

1. Create directory structure:
   ```bash
   mkdir -p staging/ap-southeast-2/vpc
   ```

2. Create configuration files:
   ```bash
   cp non-prod/account.hcl staging/
   cp -r non-prod/ap-southeast-2/* staging/ap-southeast-2/
   ```

3. Update workflow to include staging:
   ```yaml
   on:
     push:
       branches:
         - main
         - develop
         - staging  # Add new branch
   ```

4. Create new workflow file for staging deployment

### Multi-Region Deployment

To deploy to multiple regions:

1. Create region directories:
   ```bash
   mkdir -p prod/us-west-2/vpc
   mkdir -p prod/eu-west-1/vpc
   ```

2. Copy and update configurations for each region

3. Update workflows to deploy to all regions:
   ```yaml
   strategy:
     matrix:
       region: [ap-southeast-2, us-west-2, eu-west-1]
   ```

---

## Security Considerations

### Least Privilege
- Grant minimum required permissions to IAM roles
- Use separate roles for each environment
- Regularly review and audit permissions

### State File Security
- S3 bucket encryption is enabled
- Bucket versioning is enabled
- DynamoDB table for state locking
- Restrict S3 bucket access

### Secrets Management
- Never commit credentials to Git
- Use GitHub Secrets for sensitive data
- Rotate credentials regularly
- Enable audit logging

---

## Support

For issues or questions:
1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Review workflow logs in GitHub Actions
3. Create an issue in the repository
4. Contact the infrastructure team

---

## References

- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS OIDC with GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
