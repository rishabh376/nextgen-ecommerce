locals {
  acct_name = substr(regexreplace(lower("${var.name}cosmos"), "[^a-z0-9]", ""), 0, 44)
}

resource "azurerm_cosmosdb_account" "this" {
  name                = local.acct_name
  resource_group_name = "rg-${var.name}-${var.locations[0]}"
  location            = var.locations[0]
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy { consistency_level = "Session" }

  dynamic "geo_location" {
    for_each = toset(var.locations)
    content {
      location          = geo_location.value
      failover_priority = index(var.locations, geo_location.value)
      zone_redundant    = true
    }
  }

  tags = var.tags
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = "ecom"
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name

  autoscale_settings { max_throughput = 4000 }
}

locals {
  containers = toset(["products", "inventory", "carts", "orders", "forecasts"])
}

resource "azurerm_cosmosdb_sql_container" "containers" {
  for_each               = local.containers
  name                   = each.value
  resource_group_name    = azurerm_cosmosdb_account.this.resource_group_name
  account_name           = azurerm_cosmosdb_account.this.name
  database_name          = azurerm_cosmosdb_sql_database.db.name
  partition_key_paths    = ["/id"]
  partition_key_version  = 2
  autoscale_settings     { max_throughput = 1000 }
}

