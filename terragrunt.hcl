# Root Terragrunt Configuration
# This file defines the remote state configuration and common variables

locals {
  # Parse the relative path to determine environment and component
  path_parts = split("/", path_relative_to_include())
  
  # Extract account type (networking, non-prod, prod) and region
  account_name = length(local.path_parts) > 0 ? local.path_parts[0] : ""
  region       = length(local.path_parts) > 1 ? local.path_parts[1] : ""
  component    = length(local.path_parts) > 2 ? local.path_parts[2] : ""
}

# Configure remote state backend
remote_state {
  backend = "s3"
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  
  config = {
    bucket         = "aws-networking-terraform"
    key            = "${local.account_name}/${local.region}/${local.component}/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
    
    # Enable versioning
    s3_bucket_tags = {
      Name        = "Terraform State Bucket"
      Environment = local.account_name
      ManagedBy   = "Terragrunt"
    }
    
    dynamodb_table_tags = {
      Name        = "Terraform Lock Table"
      Environment = local.account_name
      ManagedBy   = "Terragrunt"
    }
  }
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      ManagedBy   = "Terragrunt"
      Environment = var.environment
      Project     = "AWS Networking"
    }
  }
}
EOF
}

# Common inputs for all modules
inputs = {
  project_name = "aws-networking"
}
