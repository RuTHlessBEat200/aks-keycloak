resource "kubernetes_namespace" "cnpg_system" {
  metadata {
    name = "cnpg-system"
  }

  depends_on = [azurerm_kubernetes_cluster.this]
}

resource "helm_release" "cnpg" {
  name       = "cnpg"
  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = var.cnpg_chart_version
  namespace  = kubernetes_namespace.cnpg_system.metadata[0].name
}

resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = "keycloak"
  }

  depends_on = [azurerm_kubernetes_cluster.this]
}

# The Cluster lives in the same namespace as Keycloak (not cnpg-system,
# where the operator itself runs) so Keycloak can read the CNPG-generated
# app secret directly - Secrets are namespace-scoped and the Bitnami chart's
# externalDatabase.existingSecret only looks in the release's own namespace.
#
# kubectl_manifest (not kubernetes_manifest) because the Cluster CRD doesn't
# exist until helm_release.cnpg has applied - kubernetes_manifest fetches
# the target CRD's OpenAPI schema at plan time and fails on a first-ever
# apply. See the same note on the ArgoCD root Application in argocd.tf's
# git history / hashicorp/terraform-provider-kubernetes#2597.
resource "kubectl_manifest" "keycloak_db_cluster" {
  yaml_body = yamlencode({
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata = {
      name      = "keycloak-db"
      namespace = kubernetes_namespace.keycloak.metadata[0].name
    }
    spec = {
      instances = 3
      storage = {
        size = "10Gi"
      }
      bootstrap = {
        initdb = {
          database = "keycloak"
          owner    = "keycloak"
        }
      }
    }
  })

  depends_on = [helm_release.cnpg]
}
