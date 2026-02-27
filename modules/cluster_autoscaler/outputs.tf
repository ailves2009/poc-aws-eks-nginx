# modules/deploy/nginx/variables.tf

output "autoscaler_role" {
  value       = data.aws_iam_role.cluster_autoscaler_role.arn
  description = "ARN of the IAM role associated with the Cluster Autoscaler Service Account"
}

output "kubeconfig" {
  value       = "AWS_PROFILE=ae-nyd-plt-target aws eks update-kubeconfig --region eu-west-3 --name poc-plt-eks --kubeconfig ~/.kube/poc-eks-kubeconfig"
  description = "Kubeconfig for the EKS cluster"
}

/*
output "cluster_autoscaler_service_account" {
  description = "Name of the Cluster Autoscaler Service Account"
  value       = try(kubernetes_service_account_v1.cluster_autoscaler_sa.metadata[0].name, "")
}

output "cluster_autoscaler_namespace" {
  description = "Namespace of the Cluster Autoscaler Service Account"
  value       = try(kubernetes_service_account_v1.cluster_autoscaler_sa.metadata[0].namespace, "")
}
*/
