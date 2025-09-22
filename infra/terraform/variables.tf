# High-level settings
variable "project"           { type = string }
variable "environment"       { type = string }
variable "regions"           { type = list(string) }            # e.g. ["eastus2","westus3"]
variable "aad_tenant_id"     { type = string }                  # Azure AD tenant GUID

# Optional: front door custom domain (not required to deploy)
variable "frontdoor_custom_domain" { type = string default = "" }

# Pipeline will set this after apps are deployed (map: region -> ingress public IP)
variable "frontdoor_backends" {
  type    = map(string)
  default = {}
}

# Optional: inject Stripe secret via TF into Key Vault (you can also set it manually later)
variable "stripe_secret" {
  type      = string
  default   = ""
  sensitive = true
}