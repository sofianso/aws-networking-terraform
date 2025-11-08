# Networking Account - Transit Gateway Configuration

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
  source = "../../../modules/transit-gateway"
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

inputs = {
  environment  = "networking"
  aws_region   = local.region_vars.locals.region
  project_name = "aws-networking"
  description  = "Transit Gateway for centralized networking hub"
  
  # Transit Gateway settings
  amazon_side_asn                         = 64512
  enable_dns_support                      = true
  enable_auto_accept_shared_attachments   = false
  enable_default_route_table_association  = false
  enable_default_route_table_propagation  = false
}
