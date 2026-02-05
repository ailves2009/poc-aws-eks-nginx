# /envs/main/plt/tst/sqs/terragrunt.hcl

terraform {
  source = "../../../../../modules/sqs"
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
    key            = "sqs/terraform.tfstate"
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

inputs = {
  queue_name                 = "tst-plt-etl-queue"
  dlq_name                   = "tst-plt-etl-dlq"

  alarm_email                = ["aleksander.ilves@echotwin.ai"]
  max_receive_count          = 5
  visibility_timeout_seconds = 30
  message_retention_seconds  = 604800 # 7 days
  receive_wait_time_seconds  = 20
  max_message_size           = 262144 # 256 KB
  delay_seconds              = 0
  sqs_managed_sse_enabled    = true
  kms_master_key_id          = null
}