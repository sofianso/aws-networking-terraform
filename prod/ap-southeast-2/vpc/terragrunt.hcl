# Prod Account - VPC Configuration (Multi-AZ)

include "root" {
  path = find_in_parent_folders()
}

include "account" {
  path = find_in_parent_folders("account.hcl")
}

include "region" {
  path = find_in_parent_folders("region.hcl")
}

terraform {
  source = "../../../modules/vpc"
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  
  # Reference Transit Gateway from networking account
  tgw_outputs_path = "../../../networking/ap-southeast-2/transit-gateway"
}

# Dependencies - Transit Gateway in networking account
dependency "transit_gateway" {
  config_path = local.tgw_outputs_path
  
  mock_outputs = {
    transit_gateway_id     = "tgw-mock-id"
    prod_route_table_id    = "tgw-rt-mock-id"
  }
  
  skip_outputs = false
}

inputs = {
  environment  = "prod"
  aws_region   = local.region_vars.locals.region
  project_name = "aws-networking"
  
  # VPC Configuration
  # Using 10.2.0.0/16 CIDR block which:
  # - Provides 65,536 IP addresses (10.2.0.0 - 10.2.255.255)
  # - Uses private IP range (10.0.0.0/8) as per RFC1918
  # - Allows room for future expansion
  vpc_cidr             = "10.2.0.0/16"
  availability_zones   = local.region_vars.locals.availability_zones  # Multi-AZ
  
  # Subnet Configuration (Multi-AZ)
  # Public subnets:
  # - Use /24 blocks providing 256 IPs each
  # - Spread across 3 AZs for high availability
  # - Located in 10.2.1-3.0/24 ranges for easy identification
  public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  # Private subnets:
  # - Also use /24 blocks with 256 IPs each
  # - Spread across same 3 AZs as public subnets
  # - Located in 10.2.11-13.0/24 ranges, separated from public ranges
  private_subnet_cidrs = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
  
  # NAT Gateway Configuration - One NAT per AZ for HA
  enable_nat_gateway   = true
  single_nat_gateway   = false  # Multi-AZ NAT Gateways for production
  
  # DNS Configuration
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Transit Gateway Integration
  transit_gateway_id              = dependency.transit_gateway.outputs.transit_gateway_id
  transit_gateway_route_table_id  = dependency.transit_gateway.outputs.prod_route_table_id
}
