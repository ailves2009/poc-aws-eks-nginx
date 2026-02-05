# /modules/sqs/main.tf

resource "aws_sqs_queue" "dlq" {
  name                       = var.dlq_name
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  message_retention_seconds  = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Encryption
  sqs_managed_sse_enabled = var.sqs_managed_sse_enabled
  kms_master_key_id       = var.kms_master_key_id
}

resource "aws_sqs_queue" "main" {
  name = var.queue_name
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds

  # Encryption
  sqs_managed_sse_enabled = var.sqs_managed_sse_enabled
  kms_master_key_id       = var.kms_master_key_id
}

resource "aws_sqs_queue_policy" "allow_s3" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.main.arn
        #Condition = {
        #  ArnLike = {
        #    "aws:SourceAccount" = var.account
        #  }
        #}
      }
    ]
  })
}
