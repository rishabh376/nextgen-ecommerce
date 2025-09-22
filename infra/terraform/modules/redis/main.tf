locals {
  redis_name = substr(regexreplace(lower("${var.name}redis"), "[^a-z0-9]", ""), 0, 63)
}

resource "azurerm_redis_cache" "this" {
  name                = local.redis_name
  location            = var.location
  resource_group_name = "rg-${var.name}-${var.location}"
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  minimum_tls_version = "1.2"
  tags                = var.tags
}

