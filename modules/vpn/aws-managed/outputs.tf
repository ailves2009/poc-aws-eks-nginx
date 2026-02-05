# /modules/vpn/outputs.tf

output "vpn_endpoint_id" {
  value = var.aws_managed_vpn_enable_vpn ? aws_ec2_client_vpn_endpoint.this[0].id : null
}

output "vpn_dns_endpoint" {
  value = var.aws_managed_vpn_enable_vpn ? aws_ec2_client_vpn_endpoint.this[0].dns_name : null
}

output "private_ca_arn" {
  description = "ARN of the AWS Private Certificate Authority"
  value       = var.aws_managed_vpn_enable_vpn ? aws_acmpca_certificate_authority.client_vpn_ca[0].arn : null
}

output "server_certificate_arn" {
  description = "ARN of the VPN server certificate"
  value       = var.aws_managed_vpn_enable_vpn ? aws_acm_certificate_validation.client_vpn_server[0].certificate_arn : null
}

output "private_ca_certificate" {
  description = "Root CA certificate (for client configuration)"
  value       = var.aws_managed_vpn_enable_vpn ? aws_acmpca_certificate.client_vpn_ca_cert[0].certificate : null
  sensitive   = true
}

output "client_cert_validity_days" {
  description = "Validity period for client certificates in days"
  value       = var.client_cert_validity_days
}

output "client_vpn_root_certificate" {
  description = "Root certificate for Client VPN authentication (for client configuration)"
  value       = var.aws_managed_vpn_enable_vpn ? tls_self_signed_cert.client_vpn_root[0].cert_pem : null
  sensitive   = true
}

output "client_vpn_root_certificate_arn" {
  description = "ARN of the imported root certificate in ACM"
  value       = var.aws_managed_vpn_enable_vpn ? aws_acm_certificate.client_vpn_root[0].arn : null
}

output "client_vpn_root_private_key" {
  description = "Private key of the root CA (for signing client certificates)"
  value       = var.aws_managed_vpn_enable_vpn ? tls_private_key.client_vpn_root[0].private_key_pem : null
  sensitive   = true
}

output "vpn_security_group_id" {
  description = "ID of the VPN endpoint security group"
  value       = var.aws_managed_vpn_enable_vpn ? aws_security_group.client_vpn[0].id : null
}
