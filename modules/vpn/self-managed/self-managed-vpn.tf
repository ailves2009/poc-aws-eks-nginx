# modules/vpn/self-managed/self-managed-vpn.tf

resource "aws_network_interface" "this" {
  subnet_id       = var.public_subnet_ids[0]
  private_ips     = [var.private_ip]
  security_groups = [aws_security_group.ec2.id]
  lifecycle { prevent_destroy = true }
  source_dest_check = false
  tags = {
    Name = "${var.client}-${var.env}-${var.tags["Purpose"]}-eni"
  }
}

# Отключает проверку Source/Destination на экземпляре (точнее — на его сетевом интерфейсе) в AWS. Обычно по умолчанию сеть отбрасывает пакеты, для которых инстанс не является конечным отправителем/получателем.
/* 
OpenVPN-сервер проксирует/маршрутизирует трафик клиентов (пакеты с клиентских IP, не имеющих адреса самого инстанса). 
Если source_dest_check проверка включена, AWS будет сбрасывать такой трафик и клиенты не смогут выходить в VPC/интернет через сервер. 
Отключение позволяет инстансу/ENI форвардить трафик.
Что ещё нужно сделать кроме отключения

Включить IP forwarding в ОС: net.ipv4.ip_forward=1 (sysctl).
- Настроить NAT/маршрутизацию (iptables MASQUERADE или routing) и правильные маршруты в VPC, (если нужно выход в интернет 
или в другие подсети). 
$ sudo iptables -t nat -vnL POSTROUTING --line-numbers
Chain POSTROUTING (policy ACCEPT 6 packets, 878 bytes)
num   pkts bytes target     prot opt in     out     source               destination         
1        0     0 MASQUERADE  0    --  *      *       10.9.0.0/16          10.0.0.0/8   

- Проверить security groups / NACL
*/

resource "aws_instance" "this" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.vpn_key.key_name
  depends_on    = [aws_key_pair.vpn_key]

  /* Depricated
  network_interface {
    network_interface_id = aws_network_interface.this.id
    device_index         = 0
  }
  */

  primary_network_interface {
    network_interface_id = aws_network_interface.this.id
    # device_index         = 0
  }

  iam_instance_profile = aws_iam_instance_profile.ssm.name
  lifecycle { prevent_destroy = true }

  tags = merge(var.tags, {
    Name = "${var.client}-${var.env}-${var.tags["Purpose"]}"
    Role = "openvpn-server"
  })

  user_data = <<EOF
#!/bin/bash
apt-get update
apt-get install -y snapd
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
# persist and enable IP forwarding for OpenVPN
cat > /etc/sysctl.d/99-openvpn.conf <<'SYSCTL'
net.ipv4.ip_forward=1
SYSCTL
# apply sysctl settings
sysctl --system || true
# report current value
sysctl net.ipv4.ip_forward
EOF
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_eip" "ec2" {
  # create EIP first (not attached) so its public_ip is known during planning
  domain = "vpc"
  tags   = var.tags
}

resource "aws_eip_association" "ec2_assoc" {
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.ec2.id
}

# Allow access to OpenVPN host
resource "aws_security_group" "ec2" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port   = var.sg_ssh_port
    to_port     = var.sg_ssh_port
    protocol    = "tcp"
    cidr_blocks = ["213.196.99.104/32", "5.172.36.89/32", "109.121.55.63/32"]
    description = "Allow SSH from well-known IPs"
  }

  ingress {
    from_port   = var.sg_openvpn_port
    to_port     = var.sg_openvpn_port
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow OpenVPN Clients UDP from all IPs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
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
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "vpn" {
  zone_id    = data.aws_route53_zone.this.zone_id       # "tst-prd.echotwin.xyz"
  name       = "vpn.${data.aws_route53_zone.this.name}" # vpn."tst-prd.echotwin.xyz"
  type       = "A"
  ttl        = 300
  records    = [aws_eip.ec2.public_ip]
  depends_on = [aws_eip.ec2, aws_eip_association.ec2_assoc]
}

resource "aws_route" "vpn_clients" {
  for_each = toset(var.private_route_table_ids)

  route_table_id         = each.value
  destination_cidr_block = var.vpn_client_cidr
  network_interface_id   = aws_network_interface.this.id
}
