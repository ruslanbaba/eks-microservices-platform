module "cloud_engineering" {
  source = "./modules/cloud"

  # Cost Optimization
  cost_optimization = {
    enable_spot_instances = true
    enable_savings_plans = true
    enable_cost_explorer = true
    budget_alerts = {
      monthly_budget = 10000
      alert_threshold_percentage = 80
    }
  }

  # Multi-Region Configuration
  multi_region = {
    enable_global_accelerator = true
    enable_route53_failover  = true
    disaster_recovery = {
      rpo_hours = 1
      rto_hours = 4
    }
  }

  # Cloud Security
  cloud_security = {
    enable_guard_duty    = true
    enable_security_hub  = true
    enable_config       = true
    enable_macie        = true
    enable_inspector    = true
  }

  # Infrastructure Optimization
  infrastructure = {
    enable_auto_scaling        = true
    enable_predictive_scaling = true
    enable_capacity_planning  = true
  }

  depends_on = [module.eks, module.security]
}
