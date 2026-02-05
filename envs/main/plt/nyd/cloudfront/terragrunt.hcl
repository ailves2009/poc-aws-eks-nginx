# /envs/main/plt/tst/cloudfront/terragrunt.hcl

terraform {
  source = "../../../../../modules/cloudfront"
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
    key            = "cloudfront/terraform.tfstate"
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

dependency "acm" {
  config_path = "../acm"
  mock_outputs = {
    cloudfront_certificate_arn = "arn:aws:acm:us-east-1:470201305353:certificate/c709791b-6994-415f-86d8-36c09ff17b0a"
  }
}

dependency "dns" {
  config_path = "../dns"
  mock_outputs = {
    hosted_zone_id = "A123456789"
  }
}

inputs = {
  name                   = "tst-plt-cloudfront"
  
  aliases                = ["data.tst-plt.echotwin.xyz"]
  acm_certificate_arn    = dependency.acm.outputs.cloudfront_certificate_arn

  create_route53_record  = true
  hosted_zone_id         = dependency.dns.outputs.hosted_zone_id
  
  # CloudFront settings
  price_class           = "PriceClass_100"  # US, Canada, Europe
  default_root_object   = "index.html"
  
  # Create OAC policy for Public bucket
  create_oac_policy     = true
}