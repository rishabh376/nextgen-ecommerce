resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${var.name}-${var.location}"
  location            = var.location
  resource_group_name = "rg-${var.name}-${var.location}"
  retention_in_days   = 30
  sku                 = "PerGB2018"
  tags                = var.tags
}