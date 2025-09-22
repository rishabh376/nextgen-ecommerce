output "rg_names" {
  value = { for r, rg in azurerm_resource_group.this : r => rg.name }
}