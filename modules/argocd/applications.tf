# ArgoCD Application for nginx (Helm chart bitnami/nginx)
# This will instruct ArgoCD to deploy a public nginx with HPA enabled.

resource "kubernetes_manifest" "argocd_app_nginx" {
  manifest = yamldecode(<<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.bitnami.com/bitnami
    chart: nginx
    targetRevision: "22.4.7"
    helm:
      values: |
        replicaCount: 1
        service:
          type: LoadBalancer
        autoscaling:
          enabled: true
          minReplicas: 1
          maxReplicas: 5
          targetCPUUtilizationPercentage: 50
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
  )
  depends_on = [helm_release.argocd]
}
