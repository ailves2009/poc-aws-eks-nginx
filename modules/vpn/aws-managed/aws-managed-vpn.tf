# /modules/vpn/aws-managed-vpn.tf

# Security Group для Client VPN Endpoint
resource "aws_security_group" "client_vpn" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  name        = "${var.client}-${var.env}-vpn-sg"
  description = "Security group for Client VPN Endpoint"
  vpc_id      = var.vpc_id

  # Разрешаем весь исходящий трафик
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  # Разрешаем входящий трафик из VPN клиентов
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpn_client_cidr]
    description = "Allow TCP traffic from VPN clients"
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [var.vpn_client_cidr]
    description = "Allow UDP traffic from VPN clients"
  }

  # Разрешаем ICMP для ping
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpn_client_cidr]
    description = "Allow ICMP from VPN clients"
  }

  tags = merge(var.tags, {
    Name = "${var.client}-${var.env}-vpn-sg"
  })
}

resource "aws_ec2_client_vpn_endpoint" "this" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  description            = var.description
  server_certificate_arn = aws_acm_certificate.client_vpn_server_custom[0].arn
  security_group_ids     = [aws_security_group.client_vpn[0].id]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.client_vpn_root[0].arn
  }

  client_cidr_block  = var.vpn_client_cidr
  split_tunnel       = var.split_tunnel
  vpc_id             = var.vpc_id
  dns_servers        = var.dns_servers
  transport_protocol = "udp"

  connection_log_options {
    enabled = false
  }

  tags = merge(var.tags, {
    Name = "${var.client}-${var.env}-vpn-endpoint"
  })

  depends_on = [
    aws_acmpca_certificate_authority_certificate.client_vpn_ca_cert,
    aws_acm_certificate.client_vpn_server_custom
  ]
}

resource "aws_ec2_client_vpn_network_association" "this" {
  for_each = var.aws_managed_vpn_enable_vpn ? toset(var.subnet_ids) : []

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  subnet_id              = each.value
}

resource "aws_ec2_client_vpn_authorization_rule" "this" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  target_network_cidr    = var.authorized_cidr
  authorize_all_groups   = true
}

# TLS private key for root CA
resource "tls_private_key" "client_vpn_root" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

# Self-signed root certificate for Client VPN
resource "tls_self_signed_cert" "client_vpn_root" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  private_key_pem = tls_private_key.client_vpn_root[0].private_key_pem

  subject {
    common_name         = "${var.client}-${var.env}-vpn-root-ca"
    country             = "AE"
    locality            = "Dubai"
    organization        = "EchoTwin"
    organizational_unit = "DevOps"
  }

  validity_period_hours = 87600 # 10 years
  is_ca_certificate     = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

# TLS private key for server certificate
resource "tls_private_key" "client_vpn_server" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

# Certificate request for server
resource "tls_cert_request" "client_vpn_server" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  private_key_pem = tls_private_key.client_vpn_server[0].private_key_pem

  subject {
    common_name         = "vpn.${var.domain_name}"
    country             = "AE"
    locality            = "Dubai"
    organization        = "EchoTwin"
    organizational_unit = "DevOps"
  }

  dns_names = [
    "vpn.${var.domain_name}",
    "*.cvpn-endpoint-*.prod.clientvpn.${var.region}.amazonaws.com"
  ]
}

# Server certificate signed by our CA
resource "tls_locally_signed_cert" "client_vpn_server" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  cert_request_pem   = tls_cert_request.client_vpn_server[0].cert_request_pem
  ca_private_key_pem = tls_private_key.client_vpn_root[0].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.client_vpn_root[0].cert_pem

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Import server certificate to ACM
resource "aws_acm_certificate" "client_vpn_server_custom" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  certificate_body  = tls_locally_signed_cert.client_vpn_server[0].cert_pem
  private_key       = tls_private_key.client_vpn_server[0].private_key_pem
  certificate_chain = tls_self_signed_cert.client_vpn_root[0].cert_pem

  tags = merge(var.tags, {
    Name = "${var.client}-${var.env}-vpn-server-cert-custom"
    Type = "Server-Certificate-Custom"
  })
}

# Import root certificate to ACM
resource "aws_acm_certificate" "client_vpn_root" {
  count = var.aws_managed_vpn_enable_vpn ? 1 : 0

  certificate_body = tls_self_signed_cert.client_vpn_root[0].cert_pem
  private_key      = tls_private_key.client_vpn_root[0].private_key_pem

  tags = merge(var.tags, {
    Name = "${var.client}-${var.env}-vpn-root-cert"
    Type = "Root-Certificate"
  })
}
