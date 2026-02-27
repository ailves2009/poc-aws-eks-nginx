# modules/vpn/outputs.tf

output "openvpn_tun0_ip" {
  value = "10.86.1.1/16"
}

output "connect_string" {
  value = try(aws_instance.ec2[0].id != "" ? "ssh -i '~/.ssh/ae/${var.key_pair_name}.pem' ubuntu@${aws_route53_record.vpn.fqdn}" : null, null)
}

output "public_ip" {
  value = try(aws_eip.ec2.public_ip, "")
}
