# /modules/vpn/ca.tf

# AWS Private Certificate Authority
resource "aws_acmpca_certificate_authority" "client_vpn_ca" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  type = "ROOT"

  certificate_authority_configuration {
    key_algorithm     = "RSA_2048"
    signing_algorithm = "SHA256WITHRSA"

    subject {
      common_name         = "${var.client}-${var.env}-vpn-ca"
      country             = "AE"
      locality            = "Dubai"
      organization        = "EchoTwin"
      organizational_unit = "DevOps"
    }
  }

  usage_mode                      = "GENERAL_PURPOSE"
  permanent_deletion_time_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.client}-${var.env}-vpn-ca"
    Type = "Private-CA"
  })
}

# Enable the Certificate Authority
resource "aws_acmpca_certificate_authority_certificate" "client_vpn_ca_cert" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  certificate_authority_arn = aws_acmpca_certificate_authority.client_vpn_ca[0].arn
  certificate               = aws_acmpca_certificate.client_vpn_ca_cert[0].certificate
  certificate_chain         = aws_acmpca_certificate.client_vpn_ca_cert[0].certificate_chain
}

# Self-signed root certificate for the CA
resource "aws_acmpca_certificate" "client_vpn_ca_cert" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  certificate_authority_arn   = aws_acmpca_certificate_authority.client_vpn_ca[0].arn
  certificate_signing_request = aws_acmpca_certificate_authority.client_vpn_ca[0].certificate_signing_request
  signing_algorithm           = "SHA256WITHRSA"

  template_arn = "arn:aws:acm-pca:::template/RootCACertificate/V1"

  validity {
    type  = "YEARS"
    value = 10
  }
}

# Server Certificate for VPN Endpoint
resource "aws_acm_certificate" "client_vpn_server" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  domain_name       = "vpn.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.client}-${var.env}-vpn-server-cert"
    Type = "Server-Certificate"
  })
}

# Route53 validation for server certificate
resource "aws_route53_record" "client_vpn_server_validation" {
  for_each = var.aws_managed_vpn_enable_vpn ? {
    for dvo in aws_acm_certificate.client_vpn_server[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.vpn[0].zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "client_vpn_server" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  certificate_arn         = aws_acm_certificate.client_vpn_server[0].arn
  validation_record_fqdns = [for record in aws_route53_record.client_vpn_server_validation : record.fqdn]
}

# Route53 zone data source
data "aws_route53_zone" "vpn" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  name         = "${var.domain_name}."
  private_zone = false
}
