# /modules/eks_kubectl/Service-Accounts.tf

# Создает ServiceAccount для AWS Load Balancer Controller
# - (kubernetes_service_account.aws_load_balancer_controller).
# Создает ServiceAccount для Cluster Autoscaler
# - (kubernetes_service_account.cluster_autoscaler).
# Применяет манифесты CRD (Custom Resource Definitions) для AWS Load Balancer Controller
# - (kubernetes_manifest.aws_lb_crd_ingressclassparams и kubernetes_manifest.aws_lb_crd_targetgroupbindings).

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = data.aws_eks_cluster.this.certificate_authority[0].data
  token                  = data.aws_eks_cluster_auth.this.token
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

#################
# SA for cloudwatch_agent
#################
resource "kubernetes_namespace_v1" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

data "aws_iam_role" "cw_observability" {
  name = var.cw_observability_role
}

resource "kubernetes_service_account_v1" "cw_observability" {
  metadata {
    name      = "cw-observability-sa"
    namespace = "amazon-cloudwatch"
    annotations = {
      "eks.amazonaws.com/role-arn" = data.aws_iam_role.cw_observability.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "cw-observability"
      "app.kubernetes.io/component"  = "observability"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}


#################
# SA for EBS-CSI Driver
#################
data "aws_iam_role" "ebs_csi_driver" {
  count = var.ebs_csi_driver_role != "" ? 1 : 0
  name  = var.ebs_csi_driver_role
}

resource "kubernetes_service_account_v1" "ebs_csi_driver" {
  count = var.ebs_csi_driver_role != "" ? 1 : 0
  metadata {
    name      = "ebs-csi-driver-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = data.aws_iam_role.ebs_csi_driver[0].arn
    }
    labels = {
      "app.kubernetes.io/name"       = "ebs-csi-driver"
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}
