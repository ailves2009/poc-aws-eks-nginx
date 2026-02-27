# /envs/main/plt/poc/alb/terragrunt.hcl

terraform {
  source = "../../../../../modules/alb"
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
    key            = "alb/terraform.tfstate"
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
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
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
provider "helm" {
  kubernetes = {
    host                   = var.kube_host
    cluster_ca_certificate = var.kube_ca
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", "eu-west-3"]
    }
  }
}
EOF
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id       = "mock-vpc-id"
  }
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name                  = "mock-cluster_name"
    load_balancer_controller_role = "mock-load-balancer-controller-role"

    kube_host                     = "mock_eks_endpoint"
    kube_ca                       = "mock_cluster_ca_certificate"
    kube_token                    = "mock_cluster_token"
  }

  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init"]
  skip_outputs = false
}

dependency "deploy" {
  config_path = "../deploy"

  mock_outputs = {
    ingress_alb_hostname = ""
  }

  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init"]
  skip_outputs = false
}

dependency "dns" {
  config_path = "../dns"

  mock_outputs = {
    hosted_zone_id = ""
  }

  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init"]
  skip_outputs = false
}

dependency "acm" {
  config_path = "../acm"

  mock_outputs = {
    wildcard_certificate_arn = ""
  }

  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init"]
  skip_outputs = false
}

inputs = {
  cluster_name                  = dependency.eks.outputs.cluster_name
  vpc_id                        = dependency.vpc.outputs.vpc_id
  load_balancer_controller_role = dependency.eks.outputs.load_balancer_controller_role

  kube_host                     = dependency.eks.outputs.eks_endpoint
  kube_ca                       = dependency.eks.outputs.cluster_ca_certificate
  kube_token                    = dependency.eks.outputs.cluster_token

  hosted_zone_id                = dependency.dns.outputs.hosted_zone_id
  ingress_alb_hostname          = dependency.deploy.outputs.ingress_alb_hostname
  certificate_arn               = dependency.acm.outputs.wildcard_certificate_arn
}