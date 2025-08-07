module "security" {
  source = "./modules/security"

  # Pod Security Standards
  enable_pod_security_policy = var.enable_pod_security_policy
  pod_security_standards = {
    enforce = "restricted"
    audit   = "restricted"
    warn    = "restricted"
  }

  # Network Policies
  enable_network_policies = var.enable_network_policies
  default_deny_all       = true

  # Secret Encryption
  encryption_config = var.encryption_configuration

  # Security Scanning
  security_scanning_config = var.security_scanning

  # Compliance
  compliance_standards = var.compliance_standards

  # IAM configurations
  enable_irsa                = true
  enable_service_accounts    = true
  enable_pod_identity        = true
  rbac_permissions_boundary  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/EKSPermissionsBoundary"

  # Audit logging
  enable_audit_logging = true
  audit_log_retention = 90

  # Container scanning
  ecr_scanning_config = {
    scan_on_push = true
    scan_frequency = "CONTINUOUS_SCAN"
  }

  # Runtime security
  runtime_security = {
    falco_enabled = true
    falco_rules_config = {
      custom_rules = true
      aggressive_rules = false
    }
  }

  depends_on = [module.eks]
}
