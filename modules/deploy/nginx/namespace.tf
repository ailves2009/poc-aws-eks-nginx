# modules/deploy/nginx/namespace.tf

resource "kubernetes_namespace_v1" "nginx_namespace" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}
