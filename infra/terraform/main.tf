locals {
  name = "${var.project}-${var.environment}"
  tags = { project = var.project, env = var.environment }
}

module "rg" {
  source   = "./modules/rg"
  name     = local.name
  regions  = var.regions
  tags     = local.tags
}

module "acr" {
  source   = "./modules/acr"
  name     = local.name
  location = var.regions[0]
  tags     = local.tags
}

module "kv" {
  source   = "./modules/kv"
  name     = local.name
  location = var.regions[0]
  tags     = local.tags
}

module "vnet" {
  source   = "./modules/vnet"
  name     = local.name
  regions  = var.regions
  tags     = local.tags
}

module "cosmos" {
  source         = "./modules/cosmos"
  name           = local.name
  locations      = var.regions
  multi_write    = true
  tags           = local.tags
}

module "redis" {
  source   = "./modules/redis"
  name     = local.name
  location = var.regions[0]
  tags     = local.tags
}

module "servicebus" {
  source   = "./modules/servicebus"
  name     = local.name
  location = var.regions[0]
  tags     = local.tags
}

module "aks" {
  source              = "./modules/aks"
  name                = local.name
  regions             = var.regions
  vnet_ids            = module.vnet.vnet_ids
  subnets             = module.vnet.subnets
  acr_id              = module.acr.acr_id
  key_vault_id        = module.kv.kv_id
  log_analytics_ws_id = module.monitor.law_id
  tags                = local.tags
}

module "frontdoor" {
  source               = "./modules/frontdoor"
  name                 = local.name
  regions              = var.regions
  backends_public_ips  = module.aks.ingress_public_ips
  custom_domain        = var.frontdoor_custom_domain
  tags                 = local.tags
}

module "monitor" {
  source   = "./modules/monitor"
  name     = local.name
  location = var.regions[0]
  tags     = local.tags
}

output "acr_login_server"  { value = module.acr.login_server }
output "aks_kubeconfigs"   { value = module.aks.kubeconfigs, sensitive = true }
output "kv_uri"            { value = module.kv.kv_uri }
output "cosmos_conn_str"   { value = module.cosmos.connection_string, sensitive = true }
output "sb_conn_str"       { value = module.servicebus.connection_string, sensitive = true }
output "redis_hostname"    { value = module.redis.hostname }
output "frontdoor_endpoint"{ value = module.frontdoor.endpoint }