# Transit Gateway Module - Variables

variable "environment" {
  description = "Environment name (networking)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "description" {
  description = "Description of the Transit Gateway"
  type        = string
  default     = "Transit Gateway for centralized networking"
}

variable "amazon_side_asn" {
  description = "Private Autonomous System Number (ASN) for the Amazon side of a BGP session"
  type        = number
  default     = 64512
}

variable "enable_dns_support" {
  description = "Enable DNS support in the Transit Gateway"
  type        = bool
  default     = true
}

variable "enable_auto_accept_shared_attachments" {
  description = "Enable automatic acceptance of attachment requests"
  type        = bool
  default     = false
}

variable "enable_default_route_table_association" {
  description = "Enable default route table association"
  type        = bool
  default     = false
}

variable "enable_default_route_table_propagation" {
  description = "Enable default route table propagation"
  type        = bool
  default     = false
}
