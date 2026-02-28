# /envs/main/plt/poc/cluster_autoscaler/terragrunt.hcl

# Skip if kubernetes cluster is not accessible (e.g., during destroy after eks is deleted)
skip = false

terraform {
  source = "../../../../../modules/cluster_autoscaler"
}

include {
  path = find_in_parent_folders("root.hcl")
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "poc-plt-terraform-state"
    key            = "cluster_autoscaler/terraform.tfstate"
    region         = "eu-west-3"
    use_lockfile   = true
    encrypt        = true
  }
}
EOF
}

generate "providers_version" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}
EOF
}

generate "providers_config" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "kubernetes" {
  host                   = var.kube_host
  cluster_ca_certificate = var.kube_ca

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", "eu-west-3"]
  }
}
EOF
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name                = "mock-cluster_name"
    cluster_autoscaler_role     = "mock-cluster-autoscaler-role"

    kube_host                   = "mock_eks_endpoint"
    kube_ca                     = "mock_cluster_ca_certificate"
    kube_token                  = "mock_cluster_token"

  }
}

dependency "eks_kubectl" {
  config_path = "../eks_kubectl"

  mock_outputs = {
    cluster_name = "mock-cluster-name"
  }
}

inputs = {
  cluster_name            = dependency.eks.outputs.cluster_name
  cluster_autoscaler_role = dependency.eks.outputs.cluster_autoscaler_role

  kube_host               = dependency.eks.outputs.eks_endpoint
  kube_ca                 = dependency.eks.outputs.cluster_ca_certificate
  kube_token              = dependency.eks.outputs.cluster_token
}