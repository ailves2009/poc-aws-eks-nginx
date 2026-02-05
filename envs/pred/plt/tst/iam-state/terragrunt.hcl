# /envs/pred/plt/tst/iam/terragrunt.hcl

terraform {
  source = "../../../../../modules/iam-state"
}

include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  cicd_role_name    = "deploy-role"
  cicd_account_arn  = "arn:aws:iam::470201305353:user/terraform"
}