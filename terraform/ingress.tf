resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }

  depends_on = [azurerm_kubernetes_cluster.this]
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_chart_version
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  # With the default externalTrafficPolicy (Cluster), Azure's LB health
  # probe hits the data-plane port (80/443) directly at path "/", which
  # nginx correctly 404s (no Ingress matches that host) - so Azure marks
  # every backend unhealthy and never forwards real traffic, even though
  # everything else (NSG, pods, in-cluster reachability) looks fine.
  # externalTrafficPolicy=Local makes Kubernetes/Azure probe the
  # controller's dedicated /healthz endpoint (port 10254) instead, and also
  # preserves real client source IPs.
  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }
}

# helm_release returns as soon as the Service object is created, but Azure's
# LoadBalancer typically takes 30s-2min longer to actually assign a public
# IP. Poll until it's non-empty so the data source below doesn't read an
# empty status.
resource "null_resource" "wait_for_ingress_ip" {
  depends_on = [helm_release.ingress_nginx]

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      for i in $(seq 1 60); do
        ip=$(kubectl get svc ingress-nginx-controller \
          -n ${kubernetes_namespace.ingress_nginx.metadata[0].name} \
          -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
        if [ -n "$ip" ]; then
          exit 0
        fi
        sleep 5
      done
      echo "Timed out waiting for ingress-nginx LoadBalancer IP" >&2
      exit 1
    EOT
  }
}

data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }

  depends_on = [null_resource.wait_for_ingress_ip]
}

locals {
  ingress_ip      = data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].ip
  argocd_hostname = "argocd.${local.ingress_ip}.sslip.io"
}
