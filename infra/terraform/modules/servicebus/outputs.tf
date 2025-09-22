output "namespace_name" { value = azurerm_servicebus_namespace.ns.name }
output "connection_string" {
  value     = azurerm_servicebus_namespace_authorization_rule.root.primary_connection_string
  sensitive = true
}