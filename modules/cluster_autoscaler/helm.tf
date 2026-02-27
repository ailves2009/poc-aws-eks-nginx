/*
provider "helm" {
  kubernetes = {
    host                   = var.kube_host
    cluster_ca_certificate = var.kube_ca
    token                  = var.kube_token
  }
}

provider "kubernetes" {
  host                   = var.kube_host
  cluster_ca_certificate = var.kube_ca
  token                  = var.kube_token
}

provider "null" {
}

data "aws_iam_role" "cluster_autoscaler" {
  name = var.cluster_autoscaler_role
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.chart_version != "" ? var.chart_version : null
  namespace  = "kube-system"
  wait       = true

  set = [
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "cluster-autoscaler"
    },
    {
      name  = "rbac.create"
      value = "false"
    },
    {
      name  = "rbac.serviceAccount.create"
      value = "false"
    },
    {
      name  = "extraArgs.expander"
      value = "least-waste"
    },
    {
      name  = "extraEnv.AWS_REGION"
      value = var.aws_region
    },
    {
      name  = "extraEnv.AWS_DEFAULT_REGION"
      value = var.aws_region
    },
    {
      name  = "cloudProvider"
      value = "aws"
    },
    {
      name  = "autoDiscovery.clusterName"
      value = var.cluster_name
    },
  ]
}

# Patch the Deployment to use the correct ServiceAccount name
# The Helm chart with create=false doesn't properly honor serviceAccount.name
resource "null_resource" "patch_cluster_autoscaler_sa" {
  provisioner "local-exec" {
    command = "kubectl -n kube-system patch deployment cluster-autoscaler-aws-cluster-autoscaler -p '{\"spec\":{\"template\":{\"spec\":{\"serviceAccountName\":\"cluster-autoscaler\"}}}}'"
  }

  depends_on = [helm_release.cluster_autoscaler]
}
*/
