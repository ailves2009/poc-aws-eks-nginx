terraform {
  source = "../../../../../modules/s3-binding"
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
    key            = "s3-binding/terraform.tfstate"
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

dependency "s3-detections" {
  config_path = "../s3-detections"
  mock_outputs = {
    s3_detection = "tst-plt-detections"
  }
}

dependency "cloudfront" {
  config_path = "../cloudfront"
  mock_outputs = {
    cloudfront_distribution_arn = "arn:aws:cloudfront::470201305353:distribution/MOCK"
  }
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id                  = "mock-vpc"
    private_route_table_ids = ["rtb-mock1", "rtb-mock2"]
  }
}

inputs = {
  bucket_name = "${dependency.s3-detections.outputs.s3_bucket_name}"

  # VPCE settings (optional)
  create_vpc_endpoint = true
  vpc_id              = "${dependency.vpc.outputs.vpc_id}"
  route_table_ids     = "${dependency.vpc.outputs.private_route_table_ids}"

  restrict_to_vpc_endpoint = true
  vpce_whitelisted_principals = [
    "arn:aws:iam::470201305353:role/deploy-role",
    # "arn:aws:iam::470201305353:role/eks-irsa-app-role",
    "arn:aws:iam::470201305353:user/aleksander.ilves-echotwin",
    "arn:aws:iam::470201305353:user/terraform",
    # "arn:aws:iam::470201305353:user/jetson",
    "*"   # temporary added because of MRT access to s3
  ]

  allow_cloudfront_access = true
  cloudfront_distribution_arn = "${dependency.cloudfront.outputs.cloudfront_distribution_arn}"
  additional_policy_statements = concat(
    dependency.cloudfront.outputs.oac_policy_statement,
    dependency.s3-detections.outputs.replication_policy_statements
  )
  cloudfront_deny_non_vpce_except_whitelisted_and_cloudfront = false
}
