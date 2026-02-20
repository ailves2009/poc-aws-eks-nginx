# /modules/iam/main.tf

data "aws_iam_role" "cicd_role" {
  name = var.cicd_role_name
}
