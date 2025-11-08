# Non-Prod Account - VPC Configuration (Single AZ)

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
    transit_gateway_id        = "tgw-mock-id"
    non_prod_route_table_id   = "tgw-rt-mock-id"
  }
  
  skip_outputs = false
}

inputs = {
  environment  = "non-prod"
  aws_region   = local.region_vars.locals.region
  project_name = "aws-networking"
  
  # VPC Configuration
  vpc_cidr             = "10.1.0.0/16"
  availability_zones   = local.region_vars.locals.availability_zones  # Single AZ
  
  # Subnet Configuration (Single AZ)
  public_subnet_cidrs  = ["10.1.1.0/24"]
  private_subnet_cidrs = ["10.1.11.0/24"]
  
  # NAT Gateway Configuration - Single NAT for cost optimization
  enable_nat_gateway   = true
  single_nat_gateway   = true  # Single NAT Gateway for non-prod
  
  # DNS Configuration
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Transit Gateway Integration
  transit_gateway_id              = dependency.transit_gateway.outputs.transit_gateway_id
  transit_gateway_route_table_id  = dependency.transit_gateway.outputs.non_prod_route_table_id
}
