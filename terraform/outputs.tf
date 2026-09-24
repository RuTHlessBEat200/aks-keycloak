output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster API server."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "resource_group_name" {
  description = "Resource group containing the AKS cluster."
  value       = azurerm_resource_group.this.name
}

output "kube_config" {
  description = "Raw kubeconfig for the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "ingress_nginx_ip" {
  description = "Public IP address of the ingress-nginx LoadBalancer."
  value       = local.ingress_ip
}

output "keycloak_url" {
  description = "Public URL for the Keycloak admin console/UI."
  value       = "https://${local.keycloak_hostname}"
}
