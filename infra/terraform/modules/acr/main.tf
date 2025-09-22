# ACR name must be globally unique and alphanumeric
locals {
  acr_name = substr(regexreplace(lower("${var.name}acr"), "[^a-z0-9]", ""), 0, 50)
}

resource "azurerm_container_registry" "this" {
  name                = local.acr_name
  resource_group_name = "rg-${var.name}-${var.location}"
  location            = var.location
  sku                 = "Premium"
  admin_enabled       = false
  tags                = var.tags

  dynamic "georeplications" {
    for_each = var.replication_locations
    content {
      location               = georeplications.value
      zone_redundancy_enabled = true
      tags                   = var.tags
    }
  }
}