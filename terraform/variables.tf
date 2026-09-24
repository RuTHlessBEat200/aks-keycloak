variable "location" {
  description = "Azure region to deploy into."
  type        = string
  default     = "switzerlandnorth"
}

variable "resource_group_name" {
  description = "Name of the resource group that will hold the AKS cluster."
  type        = string
  default     = "aks-keycloak"
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
  default     = "aks-keycloak"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster. Leave null to use AKS's current default."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Number of nodes in the default node pool."
  type        = number
  default     = 3
}

variable "node_vm_size" {
  description = "VM size for the default node pool."
  type        = string
  default     = "Standard_D2ds_v6"
}

variable "cnpg_chart_version" {
  description = "Version of the cloudnative-pg (CNPG operator) Helm chart to install."
  type        = string
  default     = "0.29.1"
}

variable "keycloak_chart_version" {
  description = "Version of the Bitnami keycloak Helm chart to install."
  type        = string
  default     = "25.2.0"
}

variable "ingress_nginx_chart_version" {
  description = "Version of the ingress-nginx Helm chart to install."
  type        = string
  default     = "4.15.1"
}

variable "cert_manager_chart_version" {
  description = "Version of the cert-manager Helm chart to install."
  type        = string
  default     = "v1.21.2"
}

variable "letsencrypt_email" {
  description = "Email address registered with Let's Encrypt ACME accounts."
  type        = string
  default     = "alessandro.udry@student.ipso.ch"
}

variable "cert_manager_cluster_issuer" {
  description = "Which cert-manager ClusterIssuer the Keycloak Ingress uses. Verified working against letsencrypt-staging; now using letsencrypt-prod for a browser-trusted cert."
  type        = string
  default     = "letsencrypt-prod"
}
