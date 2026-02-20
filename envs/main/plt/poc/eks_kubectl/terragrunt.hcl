# /envs/main/plt/poc/eks_kubectl/terragrunt.hcl

terraform {
  source = "../../../../../modules/eks_kubectl"
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
    key            = "eks_kubectl/terraform.tfstate"
    region         = "eu-west-3"
    use_lockfile   = true
    encrypt        = true
  }
}
EOF
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name                        = "mock-cluster_name"
    ebs_csi_driver_role                 = "mock-ebs-csi-driver-role"
    eks_irsa_app_role                   = "mock-eks-irsa-app-role"
    load_balancer_controller_role       = "mock-load-balancer-controller-role"
    cluster_autoscaler_role             = "mock-cluster-autoscaler-role"
    cw_observability_role               = "mock-cw-observability-role"
  }
}

inputs = {
  cluster_name                        = dependency.eks.outputs.cluster_name
  ebs_csi_driver_role                 = dependency.eks.outputs.ebs_csi_driver_role
  eks_irsa_app_role                   = dependency.eks.outputs.eks_irsa_app_role
  load_balancer_controller_role       = dependency.eks.outputs.load_balancer_controller_role
  cluster_autoscaler_role             = dependency.eks.outputs.cluster_autoscaler_role
  cw_observability_role               = dependency.eks.outputs.cw_observability_role
}