locals {
  keycloak_hostname = "auth.${local.ingress_ip}.sslip.io"
}

resource "kubernetes_secret" "keycloak_admin" {
  metadata {
    name      = "keycloak-admin-secret"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }

  data = {
    password = data.external.keycloak_secrets.result.admin_password
  }

  type = "Opaque"
}

resource "helm_release" "keycloak" {
  name = "keycloak"
  # charts.bitnami.com (classic HTTP repo) is stale post-Broadcom migration
  # and doesn't reliably resolve current image tags - use the maintained
  # OCI registry path instead.
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "keycloak"
  version    = var.keycloak_chart_version
  # Same namespace as the CNPG cluster: the Bitnami chart's
  # externalDatabase.existingSecret only looks up secrets in Keycloak's own
  # namespace, and Secrets are namespace-scoped, so this avoids having to
  # replicate the CNPG-generated app secret across namespaces.
  namespace = kubernetes_namespace.keycloak.metadata[0].name

  # As of the 2025 Bitnami/Broadcom migration, the free-tier images moved to
  # the bitnamilegacy namespace - bitnami/keycloak on Docker Hub no longer
  # reliably carries the tag this chart version defaults to.
  set {
    name  = "image.repository"
    value = "bitnamilegacy/keycloak"
  }

  set {
    name  = "global.security.allowInsecureImages"
    value = "true"
  }

  set {
    name  = "replicaCount"
    value = "2"
  }

  set {
    name  = "postgresql.enabled"
    value = "false"
  }

  set {
    name  = "externalDatabase.host"
    value = "keycloak-db-rw.${kubernetes_namespace.keycloak.metadata[0].name}.svc.cluster.local"
  }

  set {
    name  = "externalDatabase.port"
    value = "5432"
  }

  set {
    name  = "externalDatabase.database"
    value = "keycloak"
  }

  set {
    name  = "externalDatabase.existingSecret"
    value = "keycloak-db-app"
  }

  set {
    name  = "externalDatabase.existingSecretUserKey"
    value = "username"
  }

  set {
    name  = "externalDatabase.existingSecretPasswordKey"
    value = "password"
  }

  set {
    name  = "auth.adminUser"
    value = "admin"
  }

  set {
    name  = "auth.existingSecret"
    value = kubernetes_secret.keycloak_admin.metadata[0].name
  }

  set {
    name  = "auth.passwordSecretKey"
    value = "password"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.ingressClassName"
    value = "nginx"
  }

  set {
    name  = "ingress.hostname"
    value = local.keycloak_hostname
  }

  set {
    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = var.cert_manager_cluster_issuer
  }

  set {
    name  = "ingress.tls"
    value = "true"
  }

  depends_on = [
    kubectl_manifest.keycloak_db_cluster,
    kubernetes_secret.keycloak_admin,
    null_resource.wait_for_ingress_ip,
    helm_release.cert_manager,
  ]
}
