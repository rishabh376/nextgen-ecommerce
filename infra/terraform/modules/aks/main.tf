# AKS Cluster with multiple node pools, OIDC, Azure Policy, and monitoring
locals {
  node_size = "Standard_D4as_v5"
}

# Create AKS per region, wired to subnet; enable OIDC, Azure Policy, and OMS. Use Azure CNI with Calico.
resource "azurerm_kubernetes_cluster" "this" {  # one per region
  for_each            = toset(var.regions)  # iterate over regions
  name                = "${var.name}-${each.key}" # cluster name with region suffix
  location            = each.key    # region from iteration
  resource_group_name = var.rg_names[each.key]  # resource group from input map
  dns_prefix          = "${var.name}-${each.key}" # DNS prefix
  oidc_issuer_enabled = true  # enable OIDC issuer for workload identity

# System node pool. 3 nodes, VMSS, spread across 3 zones for high availability.
  default_node_pool {
    name                           = "sys"  # system node pool
    vm_size                        = "Standard_D4s_v5"  # D4s_v5 has 4 vCPU and 16 GB RAM, good for system pods
    node_count                     = 3  # Start with 3 nodes
    vnet_subnet_id                 = var.subnets[each.key]  # subnet from input map
    type                           = "VirtualMachineScaleSets"  # VMSS for better scaling
    zones                          = [1, 2, 3] # Spread across 3 zones for high availability
    only_critical_addons_enabled   = true # Only system addons
  }

# Enable Managed Identity for the cluster
  identity { type = "SystemAssigned" }  # system assigned managed identity
  azure_policy_enabled = true # Enable Azure Policy add-on

# Networking with Azure CNI and Calico
  network_profile {
    network_plugin    = "azure"   # Azure CNI
    network_policy    = "calico"  # Calico for network policy enforcement
    load_balancer_sku = "standard"  # Standard LB for better features
    outbound_type     = "loadBalancer" # Use load balancer for outbound traffic
  }

# Enable monitoring via OMS. Link to Log Analytics workspace.
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_ws_id  # Log Analytics workspace ID
  }

  tags = var.tags # Apply tags to the cluster
}

# Workload node pool. Autoscale enabled. Starts at 3 nodes, scales to 50. User node pool.
resource "azurerm_kubernetes_cluster_node_pool" "workload" {  # workload node pool
  for_each               = azurerm_kubernetes_cluster.this  # one per cluster
  name                   = "work" # workload node pool
  kubernetes_cluster_id  = each.value.id  # link to cluster
  vm_size                = local.node_size  # VM size from local variable
  node_count             = 3  # Start with 3 nodes
  min_count              = 3  # Min 3 nodes
  max_count              = 50 # Scale up to 50 nodes
  mode                   = "User" # User node pool
  upgrade_settings { max_surge = "50%" }# Allow surge upgrades. Default is 33%. Set to 50% for faster upgrades.
}

# Spot node pool for cost savings. Autoscale enabled, starts at 0 nodes.
resource "azurerm_kubernetes_cluster_node_pool" "spot" {  # spot node pool for cost savings
  for_each               = azurerm_kubernetes_cluster.this # one per cluster
  name                   = "spot" # spot node pool
  kubernetes_cluster_id  = each.value.id  # link to cluster
  vm_size                = "Standard_D4ads_v5" # Cheaper variant of D4as_v5
  node_count             = 0  # Start at 0 nodes
  min_count              = 0  # Min 0 nodes
  max_count              = 100 # Scale up to 100 spot nodes
  priority               = "Spot" # Spot instances
  eviction_policy        = "Delete" # Evict when spot price exceeds max price
  node_taints            = ["spot=true:NoSchedule"] # Taint to ensure only spot workloads land here
  mode                   = "User" # User node pool
}

# Grant AKS kubelet identity ACR Pull. Assumes ACR is in same tenant.
resource "azurerm_role_assignment" "acr_pull" { # grant ACR Pull role
  for_each             = azurerm_kubernetes_cluster.this # one per cluster. 
  scope                = var.acr_id # ACR resource ID from input variable
  role_definition_name = "AcrPull"  # built-in role name for ACR Pull
  principal_id         = each.value.kubelet_identity[0].object_id # kubelet identity object ID
}

# Grant AKS kubelet identity Key Vault Secrets User (for CSI driver to fetch secrets)
resource "azurerm_role_assignment" "kv_secrets_user" {  # grant Key Vault Secrets User role to kubelet identity
  for_each             = azurerm_kubernetes_cluster.this  # one per cluster
  scope                = var.key_vault_id # Key Vault resource ID from input variable
  role_definition_name = "Key Vault Secrets User" # built-in role name for Key Vault Secrets User
  principal_id         = each.value.kubelet_identity[0].object_id # kubelet identity object ID
}

