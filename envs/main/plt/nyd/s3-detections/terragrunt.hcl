# /envs/main/plt/tst/s3-detections/terragrunt.hcl

terraform {
  source = "../../../../../modules/s3"
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
    key            = "s3-detections/terraform.tfstate"
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

dependency "sqs" {
  config_path = "../sqs"
  mock_outputs = {
    sqs-etl-queue_arn = "moc-etl_queue_arn"
  }
}
/*
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id                  = "mock-vpc"
    private_route_table_ids = ["rtb-mock1", "rtb-mock2"]
  }
}
*/

inputs = {
  bucket_name               = "tst-plt-detections"
  acl                       = null                       # "private"
  control_object_ownership  = true
  object_ownership          = "BucketOwnerEnforced"      # "ObjectWriter"
  force_destroy             = true
  
  versioning = {
    enabled = false
  }
  # (VPCE and CloudFront binding moved to s3-binding module)

  block_public_policy       = false   # must be true, but temporary false because of MRT access to s3
  restrict_public_buckets   = false   # must be true, but temporary false because of MRT access to s3
  ignore_public_acls        = false   # must be true, but temporary false because of MRT access to s3
  block_public_acls         = false   # must be true, but temporary false because of MRT access to s3
  enable_public_write       = true

  enable_sqs_notification   = true
  sqs_queue_arn             = dependency.sqs.outputs.sqs-etl-queue_arn
  # filter_prefix           = "input/"
  # filter_suffix           = ".json"

  # replication helpers (destination needs to know the source role ARN to allow it)
  replication_enabled         = false
  source_account_id           = "875004833186"
  source_replication_role_arn = "arn:aws:iam::875004833186:role/AWSServiceForS3Replication"

  cors_rule = [
    {
        allowed_headers = ["*"]
        allowed_methods = ["GET"]
        allowed_origins = ["*"]
        expose_headers  = ["Content-Length"]
    }
    ]
}