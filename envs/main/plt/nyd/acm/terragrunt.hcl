# /envs/main/plt/tst/terragrunt.hcl

terraform {
  source = "../../../../../modules/acm"
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
    bucket         = "tst-plt-terraform-state"
    key            = "acm/terraform.tfstate"
    region         = "eu-west-3"
    use_lockfile   = true
    encrypt        = true
  }
}
EOF
}

dependency "dns" {
  config_path ="../dns"

  mock_outputs = {
    domain_name = "mock-domain-name"
  }
}

inputs = {
  enable_monitoring       = true
  alarm_email             = ["aleksander.ilves@echotwin.ai"]
  create_sns_topic        = true
  sns_topic_name          = "acm-certificates"
  
  # Create CloudFront certificate in us-east-1
  create_cloudfront_certificate = true
}