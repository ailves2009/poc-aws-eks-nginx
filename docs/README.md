cd et-iaac/envs/pred/plt/poc/s3-state
 % AWS_PROFILE=ae-poc-plt-init terragrunt apply
cd et-iaac/envs/pred/plt/poc/iam-state
 % AWS_PROFILE=ae-poc-plt-init terragrunt apply

 which helm || echo "helm not found"
helm version
helm repo list
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
ls -la ~/Library/Caches/helm/repository

AWS_PROFILE=sso-5353-us-east-2 aws eks update-kubeconfig --region eu-west-3 --name poc-plt-eks --kubeconfig ~/.kube/5353-poc-plt-kubeconfig



 iam-state
 s3-state
 iam
 vpc
 dns
 acm
 key-name

 eks
 eks_kubectl
 monitoring


to do:
network policy / istio
monitoring/logging/Prometheus
Metrics
HPA и Autoscaler
Route53 имя nginx

EBS-CSI role проверить после создания
убрать лишние права у LB role

13:31:56.572 STDOUT terraform:   # module.eks.aws_cloudwatch_log_group.this[0] will be created
13:31:56.572 STDOUT terraform:   + resource "aws_cloudwatch_log_group" "this" {
13:31:56.572 STDOUT terraform:       + arn                         = (known after apply)
13:31:56.572 STDOUT terraform:       + deletion_protection_enabled = (known after apply)
13:31:56.572 STDOUT terraform:       + id                          = (known after apply)
13:31:56.572 STDOUT terraform:       + log_group_class             = (known after apply)
13:31:56.572 STDOUT terraform:       + name                        = "/aws/eks/poc-plt-eks/cluster"
13:31:56.572 STDOUT terraform:       + name_prefix                 = (known after apply)
13:31:56.572 STDOUT terraform:       + region                      = "eu-west-3"
13:31:56.572 STDOUT terraform:       + retention_in_days           = 90
13:31:56.572 STDOUT terraform:       + skip_destroy                = false
13:31:56.572 STDOUT terraform:       + tags                        = {
13:31:56.572 STDOUT terraform:           + "Environment" = "plt"
13:31:56.572 STDOUT terraform:           + "Name"        = "/aws/eks/poc-plt-eks/cluster"
13:31:56.572 STDOUT terraform:           + "Terraform"   = "true"
13:31:56.572 STDOUT terraform:         }
13:31:56.572 STDOUT terraform:       + tags_all                    = {
13:31:56.572 STDOUT terraform:           + "Account"     = "470201305353"
13:31:56.572 STDOUT terraform:           + "Client"      = "poc"
13:31:56.572 STDOUT terraform:           + "Env"         = "main"
13:31:56.572 STDOUT terraform:           + "Environment" = "plt"
13:31:56.572 STDOUT terraform:           + "Managed"     = "terraform"
13:31:56.572 STDOUT terraform:           + "Name"        = "/aws/eks/poc-plt-eks/cluster"
13:31:56.572 STDOUT terraform:           + "Terraform"   = "true"
13:31:56.572 STDOUT terraform:         }
13:31:56.572 STDOUT terraform:     }