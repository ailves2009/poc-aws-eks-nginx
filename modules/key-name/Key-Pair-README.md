# modules/key-pair

Module to create (or import) an AWS `aws_key_pair`. Can generate a private key locally and optionally write it to a file on the machine running Terraform.

Usage examples:

1) Generate new keypair and output private key (private key will be in state — treat as sensitive):

```hcl
module "kp" {
  source        = "../../modules/key-pair"
  key_name      = "nyd-plt-key"
  generate_key  = true
  write_private_key_file = false
}
```

After `terraform apply` or `terragrunt apply` you can download the private key via:

```bash
# Terraform
terraform output -raw private_key_pem > '~/.ssh/ae/5353-us-east-2.pem'
chmod 600 ~/.ssh/ae/5353-us-east-2.pem

# Or with Terragrunt
terragrunt output -raw private_key_pem > nyd-plt-key.pem
chmod 600 nyd-plt-key.pem
```

2) Generate new keypair and write private key to local file during apply:

```hcl
module "kp" {
  source               = "../../modules/key-pair"
  key_name             = "nyd-plt-key"
  generate_key         = true
  write_private_key_file = true
  private_key_path     = "./secrets/nyd-plt-key.pem"
}
```

3) Import an existing public key (no private key will be available from Terraform):

```hcl
module "kp" {
  source       = "../../modules/key-pair"
  key_name     = "nyd-plt-key"
  generate_key = false
  public_key   = file("~/.ssh/id_rsa.pub")
}
```

Security notes:
- If you generate the private key inside Terraform, the private key value will be stored in the Terraform state (even if marked sensitive). Protect access to your state (S3 bucket + DynamoDB locking, encryption, IAM permissions).
- Prefer generating keys outside Terraform and importing only the public key when possible.
- Writing the private key to disk via `local_file` will create the file on the machine running Terraform — ensure secure handling.
