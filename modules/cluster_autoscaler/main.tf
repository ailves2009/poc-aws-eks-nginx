# modules/cluster_autoscaler/main.tf

# Configure Kubernetes provider for EKS cluster
#################
# SA for cluster_autoscaler
#################
/*
  - creates a Kubernetes ServiceAccount in kube-system annotated with the
    IAM role.
  - deploys the Cluster Autoscaler using pure Terraform resources and configures
    AWS auto-discovery to use the cluster name and ASG tags.
*/
data "aws_iam_role" "cluster_autoscaler_role" {
  name = var.cluster_autoscaler_role
}

resource "kubernetes_service_account_v1" "cluster_autoscaler_sa" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = data.aws_iam_role.cluster_autoscaler_role.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "cluster-autoscaler"
      "app.kubernetes.io/component"  = "autoscaler"
      "app.kubernetes.io/managed-by" = "terraform"
      "k8s-addon"                    = "cluster-autoscaler.addons.k8s.io"
      # "k8s-app"                      = "cluster-autoscaler"
    }
  }
}

#################
# ClusterRole + ClusterRoleBinding for Cluster Autoscaler
#################

resource "kubernetes_cluster_role_v1" "cluster_autoscaler_cr" {
  metadata {
    name = "cluster-autoscaler"
    labels = {
      "app.kubernetes.io/name" = "cluster-autoscaler"
      "k8s-addon"              = "cluster-autoscaler.addons.k8s.io"
      # "k8s-app"                = "cluster-autoscaler"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["events", "endpoints"]
    verbs      = ["create", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/eviction"]
    verbs      = ["create"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups     = [""]
    resources      = ["endpoints"]
    resource_names = ["cluster-autoscaler"]
    verbs          = ["get", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["watch", "list", "get", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods", "services", "replicationcontrollers", "persistentvolumeclaims", "persistentvolumes"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["replicasets", "daemonsets"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["watch", "list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["statefulsets", "daemonsets", "replicasets", "deployments"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["batch", "extensions"]
    resources  = ["jobs"]
    verbs      = ["get", "list", "watch", "patch"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["create", "get", "list", "watch", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["verticalpodautoscalers"]
    verbs      = ["watch", "list"]
  }
}

# role for the cluster autoscaler
resource "kubernetes_role_v1" "cluster_autoscaler_r" {
  metadata {
    name = "cluster-autoscaler"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      # "k8s-app"   = "cluster-autoscaler"
    }
    namespace = kubernetes_service_account_v1.cluster_autoscaler_sa.metadata[0].namespace
  }
  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create", "list", "watch"]
  }
  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["cluster-autoscaler-status", "cluster-autoscaler-priority-expander"]
    verbs          = ["delete", "get", "update", "watch"]
  }
}

# cluster role binding for the cluster autoscaler
resource "kubernetes_cluster_role_binding_v1" "cluster_autoscaler_crb" {
  metadata {
    name = "cluster-autoscaler"
    labels = {
      k8s-addon = "cluster-autoscaler.addons.k8s.io"
      # k8s-app   = "cluster-autoscaler"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.cluster_autoscaler_cr.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.cluster_autoscaler_sa.metadata[0].name
    namespace = kubernetes_service_account_v1.cluster_autoscaler_sa.metadata[0].namespace
  }
}

# role binding for the cluster autoscaler
resource "kubernetes_role_binding_v1" "cluster_autoscaler_rb" {
  metadata {
    name = "cluster-autoscaler"
    labels = {
      k8s-addon = "cluster-autoscaler.addons.k8s.io"
      # k8s-app   = "cluster-autoscaler"
    }
    namespace = kubernetes_service_account_v1.cluster_autoscaler_sa.metadata[0].namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.cluster_autoscaler_r.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.cluster_autoscaler_sa.metadata[0].name
    namespace = kubernetes_service_account_v1.cluster_autoscaler_sa.metadata[0].namespace
  }
}

# deployment for the cluster autoscaler
resource "kubernetes_deployment_v1" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = kubernetes_service_account_v1.cluster_autoscaler_sa.metadata[0].namespace
    labels = {
      app = "cluster-autoscaler"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "cluster-autoscaler"
      }
    }
    template {
      metadata {
        labels = {
          app = "cluster-autoscaler"
        }
        annotations = {
          "cluster-autoscaler.kubernetes.io/safe-to-evict" : false
        }
      }
      spec {
        service_account_name = kubernetes_service_account_v1.cluster_autoscaler_sa.metadata[0].name
        container {
          name  = "cluster-autoscaler"
          image = "registry.k8s.io/autoscaling/cluster-autoscaler:v1.30.3"
          command = [
            "./cluster-autoscaler",
            "--v=4",
            "--stderrthreshold=info",
            "--cloud-provider=aws",
            "--skip-nodes-with-local-storage=false",
            "--expander=least-waste",
            "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${var.cluster_name}",
            "--balance-similar-node-groups",
            "--skip-nodes-with-system-pods=false",
            "--scale-down-enabled=true",
            "--scale-down-delay-after-add=10m",
          ]
          resources {
            limits = {
              cpu    = "1000m"
              memory = "600Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "600Mi"
            }
          }
          image_pull_policy = "Always"
          volume_mount {
            name       = "ssl-certs"
            mount_path = "/etc/ssl/certs" #/ca-certificates.crt" # /etc/ssl/certs/ca-bundle.crt for Amazon Linux
            read_only  = true
            # sub_path  = "ca-bundle.crt"
          }
        }
        volume {
          name = "ssl-certs"
          host_path {
            path = "/etc/ssl/certs" #/ca-bundle.crt"
            type = "Directory"
          }
        }
      }
    }
  }
}
