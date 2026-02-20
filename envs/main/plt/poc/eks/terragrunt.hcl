# /envs/main/plt/poc/eks/terragrunt.hcl

terraform {
  source = "../../../../../modules/eks"
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
    key            = "eks/terraform.tfstate"
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

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id       = "mock-vpc-id"
    private_subnet_ids = ["mock-subnet-1", "mock-subnet-2"]
  }
}

dependency "key-name" {
  config_path = "../key-name"

  mock_outputs = {
    key-name  = "mock-key_name"
  }
}

inputs = {
  cluster_name          = "poc-plt-eks"
  kubernetes_version    = "1.33"

  endpoint_public_access                    = true
  endpoint_private_access                   = true
  enable_cluster_creator_admin_permissions  = true

  /* endpoint_public_access_cidrs           = [
    # Security: Restrict EKS API server access to specific IP ranges
    "5.172.36.89/32",       # Orion
    "213.196.99.104/32",    # Nikolas
    "109.245.37.26/32"     # Yettel
  ] */

  create_iam_role                     = true # Determines whether an IAM role is created for the cluster
  ebs_csi_driver_role                 = "ebs-csi-driver-role"
  eks_irsa_app_role                   = "eks-irsa-app-role"
  load_balancer_controller_role       = "load-balancer-controller-role"
  cluster_autoscaler_role             = "cluster-autoscaler-role"
  cw_observability_role               = "cw-observability-role"

  vpc_id                              = dependency.vpc.outputs.vpc_id
  subnet_ids                          = dependency.vpc.outputs.private_subnet_ids
  control_plane_subnet_ids            = dependency.vpc.outputs.private_subnet_ids # be better to do separate from subnet_ids
  use_latest_ami_release_version      = true
  force_update_version                = false

  namespace                           = "poc-plt"
  service_account_names               = ["app-front-sa", "app-be-sa"]

  cloudwatch_logs_retention_in_days   = 365
  node_group_ami_type                 = "AL2023_x86_64_STANDARD"
  instance_types                      = ["t3.small"]

  min_size                            = 1
  max_size                            = 5
  desired_size                        = 4
  
  key_name                            = dependency.key-name.outputs.key_name
}