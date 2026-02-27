# /modules/argocd/argocd.tf

# providers and EKS data (adapt to your existing pattern)
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = data.aws_eks_cluster.this.certificate_authority[0].data
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = data.aws_eks_cluster.this.certificate_authority[0].data
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

resource "null_resource" "helm_repo_update" {
  provisioner "local-exec" {
    command = "helm repo add argo https://argoproj.github.io/argo-helm || true && helm repo add bitnami https://charts.bitnami.com/bitnami || true && helm repo update"
  }
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name   = "argocd"
    labels = { "app.kubernetes.io/name" = "argocd" }
  }
}

resource "helm_release" "argocd" {
  depends_on       = [null_resource.helm_repo_update]
  name             = "argocd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  create_namespace = true
  upgrade_install  = true
  values = [
    file("${path.module}/values/argocd.yaml")
  ]
  timeout = 600
  wait    = true
}
