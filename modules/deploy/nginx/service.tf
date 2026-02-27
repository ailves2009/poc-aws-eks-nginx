# modules/deploy/nginx/service.tf

resource "kubernetes_service_v1" "nginx" {
  metadata {
    name      = "nginx-demo-lb"
    namespace = kubernetes_namespace_v1.nginx_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "nginx-demo"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_namespace_v1.nginx_namespace]
}
