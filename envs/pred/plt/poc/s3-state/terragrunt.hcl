# /envs/pred/plt/poc/s3-state/terragrunt.hcl

terraform {
  source = "../../../../../modules/s3-state"
}

include {
  path = find_in_parent_folders("root.hcl")
}

dependency "iam-state" {
  config_path = "../iam-state"

  mock_outputs = {
    deploy_role_arn = "mock-iam-output"
  }
}

inputs = {
  bucket_name               = "poc-plt-terraform-state"
  versioning                = false
  deploy_role_arn           = dependency.iam-state.outputs.deploy_role_arn
}
