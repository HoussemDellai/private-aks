terraform {
  backend "azurerm" {
    resource_group_name  = "terraform023_state_rg"
    storage_account_name = "tfstate023storage"
    container_name       = "tfstate"
    key                  = "stage2.terraform.tfstate"
  }
}