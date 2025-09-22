# Allocate /16 per region from 10.0.0.0/8; AKS subnet gets a /24
locals {
  vnet_cidrs = { for r in var.regions : r => cidrsubnet("10.0.0.0/8", 8, index(var.regions, r)) }
}

resource "azurerm_virtual_network" "this" {
  for_each            = toset(var.regions)
  name                = "vnet-${var.name}-${each.key}"
  location            = each.key
  resource_group_name = var.rg_names[each.key]
  address_space       = [local.vnet_cidrs[each.key]]
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  for_each             = toset(var.regions)
  name                 = "snet-aks"
  resource_group_name  = var.rg_names[each.key]
  virtual_network_name = azurerm_virtual_network.this[each.key].name
  address_prefixes     = [cidrsubnet(local.vnet_cidrs[each.key], 8, 1)] # e.g. 10.x.1.0/24
  service_endpoints    = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
  
  delegation {
    name = "aks-delegation"
    service_delegation {
      name = "Microsoft.ContainerService/managedClusters"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies"
      ]
    }
  }
}