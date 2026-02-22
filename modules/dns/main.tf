# modules/dns/main.tf

locals {
  tags = {
    Source = "dns/main.tf"
  }
}

resource "aws_route53_zone" "this" {
  name          = var.domain_name
  force_destroy = var.force_destroy

  tags = local.tags
}
