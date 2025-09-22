# One RG per region keeps resources tidy and supports zonal deploys
resource "azurerm_resource_group" "this" {
  for_each = toset(var.regions)
  name     = "rg-${var.name}-${each.key}"
  location = each.key
  tags     = var.tags
}