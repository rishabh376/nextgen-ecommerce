terraform {
  required_version = ">= 1.6.0"
  backend "azurerm" {
    resource_group_name  = var.tf_state_rg
    storage_account_name = var.tf_state_sa
    container_name       = var.tf_state_container
    key                  = "ecom/terraform.tfstate"
  }
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.115" }
    random  = { source = "hashicorp/random" }
  }
}
provider "azurerm" {
  features {}
}