# /envs/main/plt/poc/root.hcl

locals {
  region        = "eu-west-3"
  account       = "470201305353"
  env           = "plt"
  client        = "poc"
  domain_name   = "poc-eks.ailves2009.com"
  tags          = {
    Env          = "plt"
    Client       = "poc"
    Managed      = "terraform"
    Account      = "470201305353"
    Project      = "poc-aws-eks-nginx"
    Github       = ".."
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
      Project     = "${local.tags["Project"]}"
      Github      = "${local.tags["Github"]}"
    }
  }
}
provider "aws" {
  region  = "us-east-1"
  alias   = "us_east_1"
  default_tags {
    tags = {
      Env         = "${local.tags["Env"]}"
      Client      = "${local.tags["Client"]}"
      Managed     = "${local.tags["Managed"]}"
      Account     = "${local.tags["Account"]}"
      Project     = "${local.tags["Project"]}"
      Github      = "${local.tags["Github"]}"
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
  domain_name    = local.domain_name
  tags           = local.tags
}
