module "platform_engineering" {
  source = "./modules/platform"

  # GitOps Configuration
  gitops_config = {
    enable_argocd        = true
    enable_flux         = false
    git_repository     = "https://github.com/your-org/gitops-repo"
    branch             = "main"
    path               = "clusters/production"
  }

  # Service Mesh Configuration
  service_mesh = {
    enable_istio        = true
    enable_linkerd      = false
    mtls_enforcement    = "STRICT"
    tracing_enabled     = true
  }

  # Developer Platform
  developer_tools = {
    enable_code_server  = true
    enable_jupyter_hub  = true
    enable_gitlab       = true
  }

  # CI/CD Pipeline
  cicd_config = {
    enable_tekton      = true
    enable_jenkins     = false
    build_timeout     = "1h"
    concurrent_builds = 10
  }

  # Platform APIs
  platform_apis = {
    enable_service_catalog = true
    enable_custom_resources = true
    api_gateway_type      = "kong"
  }

  depends_on = [module.eks, module.security]
}
