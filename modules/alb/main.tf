# modules/alb/main.tf

#################
# SA for load_balancer_controller
#################
data "aws_iam_role" "aws_load_balancer_controller" {
  name = var.load_balancer_controller_role
}

# Kubernetes Service Account for AWS Load Balancer Controller
resource "kubernetes_service_account_v1" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = data.aws_iam_role.aws_load_balancer_controller.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Route53 CNAME record for nginx ALB
resource "aws_route53_record" "nginx_alb" {
  count   = var.hosted_zone_id != "" && var.domain_name != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = "nginx.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.ingress_alb_hostname]
}
