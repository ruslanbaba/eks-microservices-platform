resource "aws_appmesh_mesh" "main" {
  name = var.mesh_name

  spec {
    service_discovery {
      dns {
        hostname_suffix = "cluster.local"
      }
    }
  }
}

# App Mesh Controller
resource "helm_release" "appmesh_controller" {
  name       = "appmesh-controller"
  namespace  = "appmesh-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "appmesh-controller"
  version    = "1.7.0"

  create_namespace = true

  set {
    name  = "region"
    value = data.aws_region.current.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.appmesh_controller_irsa_role.iam_role_arn
  }
}

# IRSA for App Mesh Controller
module "appmesh_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.0"

  role_name                      = "appmesh-controller"
  attach_appmesh_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = data.aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["appmesh-system:appmesh-controller"]
    }
  }
}

# Outputs
output "mesh_id" {
  value = aws_appmesh_mesh.main.id
}

output "mesh_arn" {
  value = aws_appmesh_mesh.main.arn
}
