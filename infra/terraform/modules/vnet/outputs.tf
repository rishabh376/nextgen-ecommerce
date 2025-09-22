output "vnet_ids" { value = { for r, v in azurerm_virtual_network.this : r => v.id } }
output "subnets"  { value = { for r, s in azurerm_subnet.aks : r => s.id } }