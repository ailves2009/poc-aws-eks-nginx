# modules/deploy/nginx/nginx.tf
/*
locals {
  name = "nginx"
  tags = {
    Name       = local.name
    File       = "modules/deploy/nginx/nginx.tf"
    Repository = "https://github.com/alexanderilves/poc-aws-eks-nginx"
  }

  # Split multi-document YAML into documents, decode each non-empty document
  raw_docs     = [for doc in split("---\n", file("${path.module}/nginx-manifests.yaml")) : trimspace(doc)]
  decoded_docs = [for d in local.raw_docs : yamldecode(d) if d != ""]

  # Ensure each manifest has the target namespace set (so resources are created in the module namespace)
  manifests = [
    for m in local.decoded_docs :
    merge(
      m,
      {
        metadata = merge(
          try(m.metadata, {}),
          { namespace = var.namespace }
        )
      }
    )
  ]

  manifests_map = { for idx, val in local.manifests : tostring(idx) => val }
}

resource "kubernetes_namespace_v1" "nginx_namespace" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_manifest" "nginx_resources" {
  for_each   = local.manifests_map
  manifest   = each.value
  depends_on = [kubernetes_namespace_v1.nginx_namespace]
}
*/
