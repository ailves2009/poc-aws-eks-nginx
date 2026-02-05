# /modules/sqs/outputs.tf

output "sqs-etl-dlq_arn" {
  value = aws_sqs_queue.dlq.arn
}

output "sqs-etl-queue_arn" {
  value = aws_sqs_queue.main.arn
}
