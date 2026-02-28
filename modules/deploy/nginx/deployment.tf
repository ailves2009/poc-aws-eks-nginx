# modules/deploy/nginx/deployment.tf

resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name      = "nginx-demo"
    namespace = kubernetes_namespace_v1.nginx_namespace.metadata[0].name
    labels = {
      app = "nginx-demo"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx-demo"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx-demo"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:1.25-alpine"
          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 30
            period_seconds        = 20
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace_v1.nginx_namespace]
}
