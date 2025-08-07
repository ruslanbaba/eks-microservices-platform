module "sre" {
  source = "./modules/sre"

  # SLO Configuration
  slo_config = {
    availability_target = 99.99
    latency_target_ms  = 200
    error_budget_policy = "burn-rate-alert"
  }

  # Monitoring and Alerting
  monitoring = {
    enable_thanos          = true
    enable_cortex         = true
    enable_loki           = true
    retention_period_days = 90
    alert_integration = {
      pagerduty = true
      slack     = true
      teams     = false
    }
  }

  # Chaos Engineering
  chaos_engineering = {
    enable_chaos_mesh     = true
    enable_chaos_monkey  = true
    scheduled_experiments = true
  }

  # Automatic Remediation
  auto_remediation = {
    enable_node_autorepair = true
    enable_pod_disruption_budget = true
    enable_horizontal_pod_autoscaling = true
    enable_vertical_pod_autoscaling = true
  }

  # Performance Testing
  performance = {
    enable_load_testing = true
    enable_benchmark_automation = true
    tools = ["k6", "locust"]
  }

  depends_on = [module.eks, module.monitoring]
}
