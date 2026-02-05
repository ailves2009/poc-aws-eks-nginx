# /modules/s3/main.tf

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.bucket_name
  acl    = var.acl

  control_object_ownership = var.control_object_ownership
  object_ownership         = var.object_ownership
  force_destroy            = var.force_destroy

  versioning = {
    enabled = var.versioning_enabled
  }
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets

  cors_rule = var.cors_rule
}

resource "aws_s3_bucket_notification" "sqs_notification" {
  count  = var.enable_sqs_notification ? 1 : 0
  bucket = module.s3_bucket.s3_bucket_id

  queue {
    queue_arn     = var.sqs_queue_arn
    events        = var.notification_events
    filter_prefix = var.filter_prefix
    filter_suffix = var.filter_suffix
  }
}

