# modules/vpn/self-managed-vpn.tf

resource "aws_instance" "ec2" {
  count             = var.enable_openvpn_ec2 ? 1 : 0
  ami               = var.ami_id
  instance_type     = var.openvpn_instance_type
  key_name          = var.key_pair_name
  source_dest_check = false


  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name
  tags = merge(var.tags, {
    Name = "openvpn"
  })

  user_data = <<EOF
#!/bin/bash
apt-get update
apt-get install -y snapd
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
EOF
}

resource "aws_eip" "ec2" {
  instance = aws_instance.ec2[0].id
  domain   = "vpc"
  tags     = var.tags
}

resource "aws_security_group" "ec2" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.sg_ssh_port
    to_port     = var.sg_ssh_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port   = var.sg_ssh_port
    to_port     = var.sg_ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.sg_openvpn_port
    to_port     = var.sg_openvpn_port
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_iam_role" "ssm" {
  name = "${var.tags["Client"]}-${var.env}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.tags["Client"]}-${var.env}-ssm-profile"
  role = aws_iam_role.ssm.name
}

data "aws_route53_zone" "this" {
  name         = var.hosted_zone_name
  private_zone = false
}

resource "aws_route53_record" "vpn" {
  zone_id = data.aws_route53_zone.this.zone_id       # "bmta-prd.echotwin.xyz"
  name    = "vpn.${data.aws_route53_zone.this.name}" # vpn."bmta-prd.echotwin.xyz"
  type    = "A"
  ttl     = 300
  # records = [aws_instance.ec2[0].public_ip]
  records = [aws_eip.ec2.public_ip]
  # depends_on = [aws_instance.ec2]
  depends_on = [aws_eip.ec2]
}
