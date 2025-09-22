terraform {
  required_version = ">= 1.6.0"
  backend "azurerm" {
    resource_group_name  = var.tf_state_rg
    storage_account_name = var.tf_state_sa
    container_name       = var.tf_state_container
    key                  = "ecom/terraform.tfstate"
  }
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    random  = { source = "hashicorp/random" }
  }
}
data "azurerm_client_config" "current" {}

provider "azurerm" {
  features {}
  subscription_id = data.azurerm_client_config.current.subscription_id
}