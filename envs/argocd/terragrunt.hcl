# /envs/main/plt/poc/argocd/terragrunt.hcl

terraform {
  source = "../../../../../modules/argocd"
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
    key            = "argocd/terraform.tfstate"
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
  }
}

inputs = {
  cluster_name  = dependency.eks.outputs.cluster_name
}