locals {
  sb_name = substr(regexreplace(lower("${var.name}sb"), "[^a-z0-9]", ""), 0, 50)
}

resource "azurerm_servicebus_namespace" "ns" {
  name                = local.sb_name
  location            = var.location
  resource_group_name = "rg-${var.name}-${var.location}"
  sku                 = "Standard"
  capacity            = 1
  tags                = var.tags
}


resource "azurerm_servicebus_queue" "payments_req" {
  name         = "payment-requests"
  namespace_id = azurerm_servicebus_namespace.ns.id
  max_delivery_count = 10
  lock_duration      = "PT30S"
  dead_lettering_on_message_expiration = true
}

resource "azurerm_servicebus_queue" "payments_res" {
  name         = "payment-results"
  namespace_id = azurerm_servicebus_namespace.ns.id
  max_delivery_count = 10
  lock_duration      = "PT30S"
  dead_lettering_on_message_expiration = true
}

# Create SAS "RootManageSharedAccessKey" for simplicity in this reference
resource "azurerm_servicebus_namespace_authorization_rule" "root" {
  name         = "RootManageSharedAccessKey"
  namespace_id = azurerm_servicebus_namespace.ns.id
  listen       = true
  send         = true
  manage       = true
}

