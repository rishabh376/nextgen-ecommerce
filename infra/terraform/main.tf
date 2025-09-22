locals {
  # Global naming/tag scheme
  name = "${var.project}-${var.environment}"
  tags = {
    project = var.project
    env     = var.environment
  }
}

# Resource Groups per region
module "rg" {
  source  = "./modules/rg"
  name    = local.name
  regions = var.regions
  tags    = local.tags
}

# ACR in primary region with geo-replication to others
module "acr" {
  source                 = "./modules/acr"
  name                   = local.name
  location               = var.regions[0]
  replication_locations  = length(var.regions) > 1 ? slice(var.regions, 1, length(var.regions)) : []
  tags                   = local.tags
}

# Key Vault (RBAC mode)
module "kv" {
  source    = "./modules/kv"
  name      = local.name
  location  = var.regions[0]
  tenant_id = var.aad_tenant_id
  tags      = local.tags
}

# Log Analytics
module "monitor" {
  source   = "./modules/monitor"
  name     = local.name
  location = var.regions[0]
  tags     = local.tags
}

# Networking (per-region VNet + AKS subnet)
module "vnet" {
  source   = "./modules/vnet"
  name     = local.name
  regions  = var.regions
  rg_names = module.rg.rg_names
  tags     = local.tags
}

# Cosmos DB (multi-region, multi-write)
module "cosmos" {
  source      = "./modules/cosmos"
  name        = local.name
  locations   = var.regions
  multi_write = true
  tags        = local.tags
}

# Redis Cache
module "redis" {
  source   = "./modules/redis"
  name     = local.name
  location = var.regions[0]
  tags     = local.tags
}

# Service Bus (Premium)
module "servicebus" {
  source   = "./modules/servicebus"
  name     = local.name
  location = var.regions[0]
  tags     = local.tags
}

# AKS clusters per region, wired to VNet and ACR; Kubelet identity gets KV + ACR roles
module "aks" {
  source               = "./modules/aks"
  name                 = local.name
  regions              = var.regions
  rg_names             = module.rg.rg_names
  vnet_ids             = module.vnet.vnet_ids
  subnets              = module.vnet.subnets
  acr_id               = module.acr.acr_id
  key_vault_id         = module.kv.kv_id
  log_analytics_ws_id  = module.monitor.law_id
  tags                 = local.tags
}

# Write core production secrets to Key Vault
# - Cosmos connection string
# - Service Bus SAS connection string
# - Redis connection string (rediss:// form)
# - Stripe secret (if provided)
resource "azurerm_key_vault_secret" "cosmos_conn" {
  name         = "COSMOS_CONN_STR"
  value        = module.cosmos.connection_string
  key_vault_id = module.kv.kv_id
}

resource "azurerm_key_vault_secret" "sb_conn" {
  name         = "SERVICEBUS_CONN_STR"
  value        = module.servicebus.connection_string
  key_vault_id = module.kv.kv_id
}

resource "azurerm_key_vault_secret" "redis_conn" {
  name         = "REDIS_CONN_STR"
  value        = module.redis.connection_string
  key_vault_id = module.kv.kv_id
}

resource "azurerm_key_vault_secret" "stripe" {
  count        = var.stripe_secret == "" ? 0 : 1
  name         = "STRIPE_SECRET"
  value        = var.stripe_secret
  key_vault_id = module.kv.kv_id
}

# Front Door (created/updated only after we know ingress IPs)
module "frontdoor" {
  source               = "./modules/frontdoor"
  count                = length(var.frontdoor_backends) == 0 ? 0 : 1
  name                 = local.name
  regions              = var.regions
  backends_public_ips  = var.frontdoor_backends
  tags                 = local.tags
}