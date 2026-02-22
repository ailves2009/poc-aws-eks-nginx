# /modules/vpc/sg.tf
/*
resource "aws_security_group" "apigw_to_nlb" {
  name        = "apigw-to-nlb-sg"
  description = "Allow traffic from API Gateway to NLB"
  vpc_id      = module.vpc.vpc_id

  # Разрешить HTTP/HTTPS трафик от API Gateway (весь интернет, либо ограничить по необходимости)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Можно ограничить под диапазоны APIGW: https://docs.aws.amazon.com/general/latest/gr/apigateway.html
    description = "Allow HTTP from API Gateway"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Можно ограничить под диапазоны APIGW
    description = "Allow HTTPS from API Gateway"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name    = "apigw-to-nlb-sg"
    Created = "vpc/sg.tf"
  }
}
*/
