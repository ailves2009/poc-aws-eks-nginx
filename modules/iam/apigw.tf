# /modules/iam/apigw.tf

resource "aws_iam_role" "apigw_s3" {
  name = "apigw-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "apigw_s3" {
  name = "apigw-access-policy"
  role = aws_iam_role.apigw_s3.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "arn:aws:s3:::${var.s3_detection}/*"
      }
    ]
  })
}
