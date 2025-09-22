# Front Door Standard/Premium. We use the ingress public IPs as origins.
resource "azurerm_cdn_frontdoor_profile" "this" {
  name     = "fdp-${var.name}"
  sku_name = "Standard_AzureFrontDoor"
  tags     = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name       = "fde-${var.name}"
  profile_id = azurerm_cdn_frontdoor_profile.this.id
  enabled    = true
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name             = "og-${var.name}"
  profile_id       = azurerm_cdn_frontdoor_profile.this.id
  session_affinity_enabled = false
  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 4
    successful_samples_required        = 3
  }
  health_probe {
    interval_in_seconds = 30
    protocol            = "Http"
    request_type        = "GET"
    path                = "/healthz"
  }
}

resource "azurerm_cdn_frontdoor_origin" "origins" {
  for_each                    = var.backends_public_ips
  name                        = "origin-${each.key}"
  profile_id                  = azurerm_cdn_frontdoor_profile.this.id
  origin_group_name           = azurerm_cdn_frontdoor_origin_group.this.name
  host_name                   = each.value            # using public IP is allowed; FQDN also works
  http_port                   = 80
  https_port                  = 443
  origin_host_header          = each.value            # send IP as host header (simple baseline)
  enabled                     = true
  priority                    = 1
  weight                      = 1000
}

resource "azurerm_cdn_frontdoor_route" "all" {
  name                   = "route-all"
  profile_id             = azurerm_cdn_frontdoor_profile.this.id
  endpoint_id            = azurerm_cdn_frontdoor_endpoint.this.id
  origin_group_id        = azurerm_cdn_frontdoor_origin_group.this.id
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  https_redirect_enabled = true
  link_to_default_domain = true
  forwarding_protocol    = "MatchRequest"
  enabled                = true
}

