# /modules/dns/dns.tf

resource "aws_route53_zone" "this" {
  name          = var.domain_name
  force_destroy = var.force_destroy

  tags = var.tags
}
