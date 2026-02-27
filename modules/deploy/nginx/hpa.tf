# modules/deploy/nginx/hpa.tf

resource "kubernetes_horizontal_pod_autoscaler_v2" "nginx" {
  metadata {
    name      = "nginx-demo-hpa"
    namespace = kubernetes_namespace_v1.nginx_namespace.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.nginx.metadata[0].name
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 50
        }
      }
    }
  }

  depends_on = [kubernetes_deployment_v1.nginx]
}
