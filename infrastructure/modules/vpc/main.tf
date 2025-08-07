module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  # Enhanced subnet configuration
  azs             = var.azs
  private_subnets = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 8, k + 4)]
  # Dedicated subnets for data layer
  database_subnets = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 8, k + 8)]
  # Dedicated subnets for cache layer
  elasticache_subnets = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 8, k + 12)]
  # Dedicated subnets for internal ALBs
  intra_subnets = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 8, k + 16)]

  # Enhanced gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
  flow_log_log_format                  = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"

  # VPC Endpoints for enhanced security and performance
  enable_s3_endpoint                 = true
  enable_dynamodb_endpoint          = true
  enable_secretsmanager_endpoint    = true
  enable_ecr_api_endpoint          = true
  enable_ecr_dkr_endpoint         = true
  enable_cloudwatch_endpoint       = true
  enable_cloudwatch_logs_endpoint  = true
  enable_sns_endpoint             = true
  enable_sqs_endpoint            = true
  enable_sts_endpoint           = true
  enable_ssm_endpoint          = true

  # Network ACLs for additional security
  manage_default_network_acl = true
  default_network_acl_tags   = { Name = "${var.cluster_name}-default" }
  
  # Enhanced security with default security group
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${var.cluster_name}-default" }

  # EKS specific tags
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"          = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                   = "1"
  }

  tags = {
    Environment = var.environment
  }
}

# Enhanced Security Groups with strict rules
resource "aws_security_group" "cluster_sg" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "EKS cluster security group with enhanced security"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    var.default_tags,
    {
      Name = "${var.cluster_name}-cluster-sg"
      SecurityLevel = "Critical"
      AutomatedBy = "Terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Cluster internal communication
resource "aws_security_group_rule" "cluster_internal" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster_sg.id
  security_group_id        = aws_security_group.cluster_sg.id
  description             = "Allow internal cluster API communication"
}

# Worker node communication
resource "aws_security_group_rule" "worker_node_ingress" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker_sg.id
  security_group_id        = aws_security_group.cluster_sg.id
  description             = "Allow worker node communication"
}

# Worker nodes security group
resource "aws_security_group" "worker_sg" {
  name        = "${var.cluster_name}-worker-sg"
  description = "Security group for worker nodes"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    var.default_tags,
    {
      Name = "${var.cluster_name}-worker-sg"
      SecurityLevel = "High"
      AutomatedBy = "Terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Allow worker nodes to communicate with each other
resource "aws_security_group_rule" "worker_node_internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.worker_sg.id
  security_group_id        = aws_security_group.worker_sg.id
  description             = "Allow worker node intercommunication"
}

# Bastion host security group
resource "aws_security_group" "bastion_sg" {
  count       = var.enable_bastion ? 1 : 0
  name        = "${var.cluster_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    var.default_tags,
    {
      Name = "${var.cluster_name}-bastion-sg"
      SecurityLevel = "High"
      AutomatedBy = "Terraform"
    }
  )
}

# WAF integration for ALB
resource "aws_wafv2_web_acl" "alb_waf" {
  name  = "${var.cluster_name}-alb-waf"
  description = "WAF ACL for ALB protection"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "ALBWAFMetric"
    sampled_requests_enabled  = true
  }
}

# Enhanced Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "elasticache_subnets" {
  description = "List of IDs of elasticache subnets"
  value       = module.vpc.elasticache_subnets
}

output "intra_subnets" {
  description = "List of IDs of intra subnets"
  value       = module.vpc.intra_subnets
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

output "vpc_flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = module.vpc.vpc_flow_log_id
}

output "vpc_flow_log_destination_arn" {
  description = "The ARN of the destination for VPC Flow Logs"
  value       = module.vpc.vpc_flow_log_destination_arn
}

output "cluster_sg_id" {
  description = "ID of the EKS cluster Security Group"
  value       = aws_security_group.cluster_sg.id
}

output "worker_sg_id" {
  description = "ID of the EKS worker nodes Security Group"
  value       = aws_security_group.worker_sg.id
}

output "bastion_sg_id" {
  description = "ID of the bastion host Security Group"
  value       = var.enable_bastion ? aws_security_group.bastion_sg[0].id : null
}

output "vpc_endpoints" {
  description = "Map of VPC endpoints created"
  value       = module.vpc.vpc_endpoints
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.alb_waf.arn
}
