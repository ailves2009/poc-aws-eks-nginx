# modules/dns/outputs.tf

output "domain_name" {
  description = "DNS zone name"
  value       = aws_route53_zone.this.name
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "Name servers assigned to the hosted zone (public zones only)"
  value       = try(aws_route53_zone.this.name_servers, [])
}

output "domain_arn" {
  description = "ARN of the hosted zone"
  value       = aws_route53_zone.this.arn
}

