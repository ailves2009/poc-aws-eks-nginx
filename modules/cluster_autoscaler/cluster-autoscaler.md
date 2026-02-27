##  Cluster Autoscaler installation (Terraform)

  - Service-Accounts.tf - creates a K8s ServiceAccount in kube-system annotated with the
    IAM role created earlier (`aws_iam_role.cluster_autoscaler`) so IRSA works.
  - Than manually we install the Cluster Autoscaler Helm chart and configures AWS auto-discovery to use the cluster name and ASG tags.

Note: If we'd like to use the Helm provider, it must be configured in the root module or via a provider block that can access the EKS cluster (for example in `modules/metrics/main.tf` we use `provider "helm" { kubernetes { config_path = "~/.kube/config" } }`).
If you prefer the helm provider configured here, add an appropriate provider block.

Note: installation of the Cluster Autoscaler Helm chart is intentionally left out of Terraform here to avoid coupling chart installation to the module-level Helm provider configuration. You can install the chart manually or via a root-level Helm release that has correct access to the cluster.

Example Helm command to run (replace ${CLUSTER_NAME} and ${REGION}):

helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set rbac.create=false \
  --set serviceAccount.create=false \
  --set serviceAccount.name=cluster-autoscaler \
  --set extraArgs[0]=--cloud-provider=aws \
  --set extraArgs[1]=--node-group-auto-discovery='asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${CLUSTER_NAME}=owned' \
  --set extraArgs[2]=--balance-similar-node-groups \
  --set extraArgs[3]=--skip-nodes-with-local-storage=false \
  --set extraArgs[4]=--v=4

Make sure ASGs are tagged with:
  k8s.io/cluster-autoscaler/enabled=true
  k8s.io/cluster-autoscaler/${CLUSTER_NAME}=owned
and that the IAM role `aws_iam_role.cluster_autoscaler` is attached to the
service account (created above) via the `eks.amazonaws.com/role-arn` annotation.
