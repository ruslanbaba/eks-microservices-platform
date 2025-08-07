resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "39.0.0"

  create_namespace = true

  values = [<<EOF
grafana:
  adminPassword: ${var.grafana_admin_password}
  persistence:
    enabled: true
    size: 10Gi
  dashboards:
    default:
      kubernetes-cluster:
        gnetId: 315
        revision: 3
        datasource: Prometheus

prometheus:
  prometheusSpec:
    retention: 15d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
EOF
  ]
}

# CloudWatch Container Insights
resource "helm_release" "cloudwatch_agent" {
  name       = "cloudwatch-agent"
  namespace  = "amazon-cloudwatch"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  version    = "0.0.7"

  create_namespace = true

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
}

# Fluentbit for log aggregation
resource "helm_release" "fluentbit" {
  name       = "fluentbit"
  namespace  = "logging"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.20.0"

  create_namespace = true

  values = [<<EOF
config:
  outputs: |
    [OUTPUT]
        Name cloudwatch
        Match *
        region ${data.aws_region.current.name}
        log_group_name /aws/eks/${var.cluster_name}/logs
        log_stream_prefix fluentbit-
        auto_create_group true
EOF
  ]
}

# Metrics server for HPA
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.8.2"

  set {
    name  = "args"
    value = "{--kubelet-insecure-tls}"
  }
}
