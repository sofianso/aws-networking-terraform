# Transit Gateway Module - Main Resources

# Transit Gateway
resource "aws_ec2_transit_gateway" "main" {
  description                     = var.description
  amazon_side_asn                 = var.amazon_side_asn
  dns_support                     = var.enable_dns_support ? "enable" : "disable"
  auto_accept_shared_attachments  = var.enable_auto_accept_shared_attachments ? "enable" : "disable"
  default_route_table_association = var.enable_default_route_table_association ? "enable" : "disable"
  default_route_table_propagation = var.enable_default_route_table_propagation ? "enable" : "disable"

  tags = {
    Name        = "${var.project_name}-${var.environment}-tgw"
    Environment = var.environment
  }
}

# Transit Gateway Route Table for Non-Prod
resource "aws_ec2_transit_gateway_route_table" "non_prod" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name        = "${var.project_name}-non-prod-tgw-rt"
    Environment = "non-prod"
  }
}

# Transit Gateway Route Table for Prod
resource "aws_ec2_transit_gateway_route_table" "prod" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name        = "${var.project_name}-prod-tgw-rt"
    Environment = "prod"
  }
}

# Transit Gateway Route Table for Networking (Central Hub)
resource "aws_ec2_transit_gateway_route_table" "networking" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name        = "${var.project_name}-networking-tgw-rt"
    Environment = "networking"
  }
}

# CloudWatch Log Group for Transit Gateway Flow Logs
resource "aws_cloudwatch_log_group" "tgw_flow_log" {
  name              = "/aws/transitgateway/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-tgw-flow-log"
    Environment = var.environment
  }
}

# Transit Gateway Flow Logs
resource "aws_flow_log" "tgw" {
  iam_role_arn         = aws_iam_role.tgw_flow_log.arn
  log_destination      = aws_cloudwatch_log_group.tgw_flow_log.arn
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"

  tags = {
    Name        = "${var.project_name}-${var.environment}-tgw-flow-log"
    Environment = var.environment
  }
}

# IAM Role for Transit Gateway Flow Logs
resource "aws_iam_role" "tgw_flow_log" {
  name = "${var.project_name}-${var.environment}-tgw-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-tgw-flow-log-role"
    Environment = var.environment
  }
}

# IAM Role Policy for Transit Gateway Flow Logs
resource "aws_iam_role_policy" "tgw_flow_log" {
  name = "${var.project_name}-${var.environment}-tgw-flow-log-policy"
  role = aws_iam_role.tgw_flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
