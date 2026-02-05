# /envs/main/plt/tst/root.hcl

locals {
  region        = "eu-west-3"
  account       = "470201305353"
  env           = "plt"
  client        = "tst"
  domain_name   = "tst-plt.echotwin.xyz"
  tags       = {
    Env         = "main"
    Client      = "tst"
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
provider "aws" {
  region  = "us-east-1"
  alias   = "us_east_1"
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
  domain_name    = local.domain_name
  tags           = local.tags
  s3_detection   = "tst-plt-detections"
}
