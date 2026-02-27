# AWS Load Balancer Ingress for nginx
# This creates an AWS ALB (Application Load Balancer) that routes traffic to nginx Service
# The ALB Controller automatically manages the AWS side when it sees this Ingress resource

resource "kubernetes_ingress_v1" "nginx_alb" {
  metadata {
    name      = "nginx-alb"
    namespace = "nginx"

    annotations = merge(
      {
        "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
        "alb.ingress.kubernetes.io/target-type" = "ip"
      },
      var.certificate_arn != "" ? {
        "alb.ingress.kubernetes.io/certificate-arn" = var.certificate_arn
        "alb.ingress.kubernetes.io/listen-ports"    = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
        "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      } : {}
    )

    labels = {
      "app.kubernetes.io/name"       = "nginx"
      "app.kubernetes.io/component"  = "load-balancer"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.nginx_hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "nginx-demo-lb"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service_v1.nginx]
}
