# /modules/eks/main.tf

data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  # version = "~> 21.0"
  version = "~>21.15.1"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access                   = var.endpoint_public_access
  endpoint_public_access_cidrs             = var.endpoint_public_access_cidrs
  endpoint_private_access                  = var.endpoint_private_access
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  addons = merge(
    {
      coredns = {}
      eks-pod-identity-agent = {
        before_compute = true
      }
      kube-proxy = {}
      vpc-cni = {
        before_compute = true
      }
    },
    var.ebs_csi_driver_role != "" ? { "aws-ebs-csi-driver" = {} } : {}
  )

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  force_update_version = var.force_update_version

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    one = {
      ami_type                       = var.node_group_ami_type
      instance_types                 = var.instance_types
      use_latest_ami_release_version = var.use_latest_ami_release_version

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      create_iam_role      = var.create_iam_role
      iam_role_arn         = aws_iam_role.eks_node_role.arn
      iam_role_description = "IAM role for EKS managed node group with necessary permissions"

      key_name = var.key_name
      tags = {
        "k8s.io/cluster-autoscaler/enabled"             = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_put_response_hop_limit = 2
        http_tokens                 = "required"
      }
    }
  }
}

