variable "name" {}
variable "regions" { type = list(string) }
variable "vnet_ids" { type = map(string) }
variable "subnets" { type = map(string) }
variable "acr_id" {}
variable "key_vault_id" {}
variable "log_analytics_ws_id" {}
variable "tags" { type = map(string) }

locals { node_size = "Standard_D4as_v5" }

resource "azurerm_kubernetes_cluster" "this" {
  for_each            = toset(var.regions)
  name                = "${var.name}-${each.key}"
  location            = each.key
  resource_group_name = "rg-${var.name}-${each.key}"
  dns_prefix          = "${var.name}-${each.key}"
  oidc_issuer_enabled = true

  default_node_pool {
    name                 = "sys"
    vm_size              = "Standard_D4s_v5"
    node_count           = 3
    type                 = "VirtualMachineScaleSets"
    orchestrator_version = "1.29"
    zones                = [1,2,3]
  }

  identity {
    type = "SystemAssigned"
  }

  azure_policy_enabled = true

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "calico"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_ws_id
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  for_each              = azurerm_kubernetes_cluster.this
  name                  = "work"
  kubernetes_cluster_id = each.value.id
  vm_size               = local.node_size
  node_count            = 3
  max_pods              = 50
  mode                  = "User"
  enable_auto_scaling   = true
  min_count             = 3
  max_count             = 50
  node_taints           = ["workload=true:NoSchedule"]
  upgrade_settings { max_surge = "50%" }
}

resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  for_each              = azurerm_kubernetes_cluster.this
  name                  = "spot"
  kubernetes_cluster_id = each.value.id
  vm_size               = "Standard_D4ads_v5"
  node_count            = 0
  enable_auto_scaling   = true
  min_count             = 0
  max_count             = 100
  priority              = "Spot"
  eviction_policy       = "Delete"
  node_taints           = ["spot=true:NoSchedule"]
}

output "kubeconfigs" {
  value = { for r, c in azurerm_kubernetes_cluster.this : r => c.kube_config_raw }
  sensitive = true
}

output "ingress_public_ips" {
  value = { for r, c in azurerm_kubernetes_cluster.this : r => "TO_BE_FILLED_BY_INGRESS_PUBLIC_IP" }
}