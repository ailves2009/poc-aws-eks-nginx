# /envs/plt/poc/root.hcl

locals {
  region     = "eu-west-3"
  account    = "470201305353"
  env        = "pred"
  client     = "poc"
  tags       = {
    Env         = "pred"
    Client      = "poc"
    Managed     = "terraform"
    Account     = "470201305353"
  }
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region  = "${local.region}"
  default_tags {
    tags = {
      Env         = "${local.tags["Env"]}"
      Client      = "${local.tags["Client"]}"
      Managed     = "${local.tags["Managed"]}"
      Account     = "${local.tags["Account"]}"
    }
  }
}
EOF
}

inputs = {
  region         = local.region
  account        = local.account
  env            = local.env
  client         = local.client
  tags           = local.tags
}