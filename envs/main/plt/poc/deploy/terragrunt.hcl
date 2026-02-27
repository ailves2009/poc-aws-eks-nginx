# /envs/main/plt/poc/deploy/nginx/terragrunt.hcl

terraform {
  source = "../../../../../modules/deploy/nginx"
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
    key            = "nginx/terraform.tfstate"
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
    cluster_name                        = "mock-cluster_name"
    eks_endpoint                        = "mock_eks_endpoint"
    cluster_ca_certificate              = "mock_cluster_ca_certificate"
    cluster_token                       = "mock_cluster_token"
  }
}

dependency "acm" {
  config_path = "../acm"

  mock_outputs = {
    wildcard_certificate_arn = ""
  }

  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init"]
}

inputs = {
  namespace               = "nginx"
  nginx_hostname          = "nginx.poc-eks.ailves2009.com"
  cluster_name            = dependency.eks.outputs.cluster_name
  kube_host               = dependency.eks.outputs.eks_endpoint
  kube_ca                 = dependency.eks.outputs.cluster_ca_certificate
  kube_token              = ""
  certificate_arn         = dependency.acm.outputs.wildcard_certificate_arn
}