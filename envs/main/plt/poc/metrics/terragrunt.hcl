# envs/main/plt/poc/metrics/terragrunt.hcl

terraform {
  source = "../../../../../modules/metrics"
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
    key            = "metrics/terraform.tfstate"
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
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}
EOF
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name                        = "mock-cluster_name"
    eks_endpoint                        = "mock_eks_endpoint"
    cluster_ca_certificate              = "mock_cluster_ca_certificate"
    cluster_token                       = "mock_cluster_token"
  }
}

inputs = {
  kube_host                   = dependency.eks.outputs.eks_endpoint
  kube_ca                     = dependency.eks.outputs.cluster_ca_certificate
  kube_token                  = dependency.eks.outputs.cluster_token
  metrics_server_helm_version = "3.13.0"
}
