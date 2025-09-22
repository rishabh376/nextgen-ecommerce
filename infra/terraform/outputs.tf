output "rg_names"            { value = module.rg.rg_names }
output "acr_login_server"    { value = module.acr.login_server }
output "acr_name"            { value = module.acr.name }
output "kv_uri"              { value = module.kv.kv_uri }
output "kv_name"             { value = module.kv.kv_name }
output "cosmos_conn_str"     { value = module.cosmos.connection_string, sensitive = true }
output "sb_conn_str"         { value = module.servicebus.connection_string, sensitive = true }
output "redis_conn_str"      { value = module.redis.connection_string, sensitive = true }
output "aks_kubeconfigs"     { value = module.aks.kubeconfigs, sensitive = true }
output "ingress_public_ips"  { value = module.aks.ingress_public_ips } # Only if you pre-provisioned; here it's blank until NGINX allocates

# Front Door endpoint (only present after front door is created)
output "frontdoor_endpoint" {
  value     = try(module.frontdoor[0].endpoint_hostname, "")
  sensitive = false
}