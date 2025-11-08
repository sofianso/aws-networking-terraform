# Networking Account - VPC Configuration

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
}

# Dependencies - Transit Gateway must exist first
dependency "transit_gateway" {
  config_path = "../transit-gateway"
  
  mock_outputs = {
    transit_gateway_id         = "tgw-mock-id"
    networking_route_table_id  = "tgw-rt-mock-id"
  }
}

inputs = {
  environment  = "networking"
  aws_region   = local.region_vars.locals.region
  project_name = "aws-networking"
  
  # VPC Configuration
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = local.region_vars.locals.availability_zones
  
  # Subnet Configuration (Multi-AZ for networking hub)
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  # NAT Gateway Configuration
  enable_nat_gateway   = true
  single_nat_gateway   = false  # Multi-AZ NAT Gateways for HA
  
  # DNS Configuration
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Transit Gateway Integration
  transit_gateway_id              = dependency.transit_gateway.outputs.transit_gateway_id
  transit_gateway_route_table_id  = dependency.transit_gateway.outputs.networking_route_table_id
}
