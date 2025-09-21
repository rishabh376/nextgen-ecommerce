variable "project" { type = string }
variable "environment" { type = string }
variable "regions" { type = list(string) }
variable "aad_tenant_id" { type = string }
variable "frontdoor_custom_domain" { type = string }
variable "tf_state_rg" { type = string }
variable "tf_state_sa" { type = string }
variable "tf_state_container" { type = string }