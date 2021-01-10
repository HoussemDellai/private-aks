terraform {
  backend "azurerm" {
    resource_group_name  = "terraform031_state_rg"
    storage_account_name = "tfstate031storage"
    container_name       = "tfstate"
    key                  = "stage1.terraform.tfstate"
  }
}