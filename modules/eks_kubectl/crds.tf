# modules/eks_kubectl/crd.tf
# We need CRD to ensure Kubernetes is aware of new resource types that use 
# the AWS LB controller (e.g., IngressClassParams, TargetGroupBinding). 
# Without the CRD controller, it's impossible to address the threat.

resource "kubernetes_manifest" "aws_lb_crd_ingressclassparams" {
  manifest = yamldecode(file("${path.module}/crds-ingressclassparams.yaml"))
}

resource "kubernetes_manifest" "aws_lb_crd_targetgroupbindings" {
  manifest = yamldecode(file("${path.module}/crds-targetgroupbindings.yaml"))
}
