# modules/key-name/key-pair.tf

resource "tls_private_key" "access_key" {
  count     = var.generate_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
  lifecycle { prevent_destroy = false }
}

resource "aws_key_pair" "access_key" {
  key_name   = var.key_name
  public_key = var.generate_key ? tls_private_key.access_key[0].public_key_openssh : var.public_key
  lifecycle { prevent_destroy = false }
}

resource "local_file" "private_key" {
  count           = var.generate_key && var.write_private_key_file ? 1 : 0
  filename        = var.private_key_path
  content         = tls_private_key.access_key[0].private_key_pem
  file_permission = var.private_key_permissions
  lifecycle { prevent_destroy = false }
}
