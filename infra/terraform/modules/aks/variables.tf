variable "name"                 { type = string }
variable "regions"              { type = list(string) }
variable "rg_names"             { type = map(string) }
variable "vnet_ids"             { type = map(string) }
variable "subnets"              { type = map(string) }
variable "acr_id"               { type = string }
variable "key_vault_id"         { type = string }
variable "log_analytics_ws_id"  { type = string }
variable "tags"                 { 
    type = map(string) 
    default = {} 
}