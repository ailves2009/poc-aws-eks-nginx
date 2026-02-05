# /envs/main/plt/tst/s3-jetson-logs/terragrunt.hcl

terraform {
  source = "../../../../../modules/s3"
}

include {
  path = find_in_parent_folders("root.hcl")
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "tst-plt-terraform-state"
    key            = "s3-jetson-logs/terraform.tfstate"
    region         = "eu-west-3"
    use_lockfile   = true
    encrypt        = true
  }
}
EOF
}

inputs = {
  bucket_name               = "tst-plt-jetson-logs"
  acl                       = null                       # "private"
  control_object_ownership  = true
  object_ownership          = "BucketOwnerEnforced"      # "ObjectWriter"
  force_destroy             = true
  
  versioning = {
    enabled = false
  }

  # (VPCE and CloudFront binding moved to s3-binding module)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPublicRead"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::tst-plt-jetson-logs/*"
      }
    ]
  })
  attach_policy = true

  block_public_policy       = true
  restrict_public_buckets   = true
  ignore_public_acls        = true
  block_public_acls         = true
  enable_public_write       = false

  cors_rule = [
    {
        allowed_headers = ["*"]
        allowed_methods = ["GET"]
        allowed_origins = ["*"]
        expose_headers  = ["Content-Length"]
    }
    ]
}