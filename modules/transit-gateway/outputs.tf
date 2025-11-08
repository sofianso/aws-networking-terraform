# Transit Gateway Module - Outputs

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.arn
}

output "transit_gateway_owner_id" {
  description = "Owner ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.owner_id
}

output "non_prod_route_table_id" {
  description = "ID of the Transit Gateway Route Table for Non-Prod"
  value       = aws_ec2_transit_gateway_route_table.non_prod.id
}

output "prod_route_table_id" {
  description = "ID of the Transit Gateway Route Table for Prod"
  value       = aws_ec2_transit_gateway_route_table.prod.id
}

output "networking_route_table_id" {
  description = "ID of the Transit Gateway Route Table for Networking"
  value       = aws_ec2_transit_gateway_route_table.networking.id
}
