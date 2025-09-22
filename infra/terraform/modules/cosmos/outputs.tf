output "account_name"   { value = azurerm_cosmosdb_account.this.name }
output "endpoint"       { value = azurerm_cosmosdb_account.this.endpoint }
output "primary_key"    { 
    value = azurerm_cosmosdb_account.this.primary_key
 sensitive = true 
 }
output "connection_string" {
  value     = "AccountEndpoint=${azurerm_cosmosdb_account.this.endpoint};AccountKey=${azurerm_cosmosdb_account.this.primary_key};"
  sensitive = true
}