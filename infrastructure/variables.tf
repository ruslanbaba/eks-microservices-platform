variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-microservices"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "node_groups" {
  description = "EKS node group configuration"
  type = map(object({
    instance_types = list(string)
    min_size      = number
    max_size      = number
    desired_size  = number
    disk_size     = number
  }))
  default = {
    general = {
      instance_types = ["t3.large"]
      min_size      = 2
      max_size      = 5
      desired_size  = 3
      disk_size     = 100
    }
    cpu-optimized = {
      instance_types = ["c5.xlarge"]
      min_size      = 1
      max_size      = 3
      desired_size  = 2
      disk_size     = 100
    }
  }
}

variable "enable_pod_security_policy" {
  description = "Enable Pod Security Policy"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Enable Kubernetes Network Policies"
  type        = bool
  default     = true
}

variable "encryption_configuration" {
  description = "EKS encryption configuration for secrets"
  type = object({
    enable_encryption = bool
    kms_key_arn      = string
  })
  default = {
    enable_encryption = true
    kms_key_arn      = ""  # Will create a new KMS key if not provided
  }
}

variable "security_scanning" {
  description = "Security scanning configuration"
  type = object({
    enable_vulnerability_scanning = bool
    enable_image_scanning        = bool
    enable_runtime_security      = bool
  })
  default = {
    enable_vulnerability_scanning = true
    enable_image_scanning        = true
    enable_runtime_security      = true
  }
}

variable "compliance_standards" {
  description = "Compliance standards to enforce"
  type        = list(string)
  default     = ["CIS", "HIPAA", "SOC2", "PCI"]
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "eks-microservices-platform"
    SecurityCompliance = "CIS-EKS-1.2"
  }
}
