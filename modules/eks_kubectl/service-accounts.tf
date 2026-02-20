# /modules/eks_kubectl/Service-Accounts.tf

# Создает ServiceAccount для AWS Load Balancer Controller 
# - (kubernetes_service_account.aws_load_balancer_controller).
# Создает ServiceAccount для Cluster Autoscaler 
# - (kubernetes_service_account.cluster_autoscaler).
# Применяет манифесты CRD (Custom Resource Definitions) для AWS Load Balancer Controller 
# - (kubernetes_manifest.aws_lb_crd_ingressclassparams и kubernetes_manifest.aws_lb_crd_targetgroupbindings).

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
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
# SA for load_balancer_controller
#################
data "aws_iam_role" "aws_load_balancer_controller" {
  name = var.load_balancer_controller_role
}

# Kubernetes Service Account for AWS Load Balancer Controller
resource "kubernetes_service_account_v1" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller-sa"
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

#################
# SA for cluster_autoscaler
#################
/*
  - creates a Kubernetes ServiceAccount in kube-system annotated with the
    IAM role created earlier (`aws_iam_role.cluster_autoscaler`) so IRSA works.
  - installs the Cluster Autoscaler Helm chart and configures AWS auto-discovery
    to use the cluster name and ASG tags.
*/
data "aws_iam_role" "cluster_autoscaler_role" {
  name = var.cluster_autoscaler_role
}

resource "kubernetes_service_account_v1" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = data.aws_iam_role.cluster_autoscaler_role.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "cluster-autoscaler"
      "app.kubernetes.io/component"  = "autoscaler"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}
#################
# SA for EBS-CSI Driver
#################
data "aws_iam_role" "ebs_csi_driver" {
  name = var.ebs_csi_driver_role
}

resource "kubernetes_service_account_v1" "ebs_csi_driver" {
  metadata {
    name      = "ebs-csi-driver-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = data.aws_iam_role.ebs_csi_driver.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "ebs-csi-driver"
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}
