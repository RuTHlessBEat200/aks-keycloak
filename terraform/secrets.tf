data "external" "azure_secrets" {
  program = ["${path.module}/scripts/decrypt-secrets.sh"]
}

data "external" "keycloak_secrets" {
  program = ["${path.module}/scripts/decrypt-keycloak-secrets.sh"]
}
