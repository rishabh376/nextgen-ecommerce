locals {
  kv_name = substr(regexreplace(lower("${var.name}kv"), "[^a-z0-9]", ""), 0, 24)
}

resource "azurerm_key_vault" "this" {
  name                          = local.kv_name
  resource_group_name           = "rg-${var.name}-${var.location}"
  location                      = var.location
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  soft_delete_retention_days    = 14
  purge_protection_enabled      = true
  public_network_access_enabled = true
  tags                          = var.tags
}