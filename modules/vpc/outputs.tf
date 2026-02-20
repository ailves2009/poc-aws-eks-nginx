# /modules/vpc/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_route_table_ids" {
  description = "Private route table IDs created by the VPC module"
  value       = module.vpc.private_route_table_ids
}

output "public_route_table_ids" {
  description = "Public route table IDs created by the VPC module"
  value       = module.vpc.public_route_table_ids
}

output "apigw_nlb_sg_id" {
  description = "ID of the security group allowing traffic from API Gateway to NLB"
  value       = aws_security_group.apigw_to_nlb.id
}
