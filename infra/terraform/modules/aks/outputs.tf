# Raw kubeconfigs (sensitive) . Use with kubectl or helm providers. Map of region to kubeconfig.
output "kubeconfigs" { # raw kubeconfigs for kubectl/helm providers
  value     = { for r, c in azurerm_kubernetes_cluster.this : r => c.kube_config_raw }  # map of region to kubeconfig.
  sensitive = true  # sensitive data
}

# Placeholder for public IPs (filled later by pipeline when NGINX is installed). Map of region to public IP.
output "ingress_public_ips" {   # placeholder for public IPs (filled later) map of region to public IP
  value = { for r, c in azurerm_kubernetes_cluster.this : r => "" } # map of region to public IP (filled later)
}