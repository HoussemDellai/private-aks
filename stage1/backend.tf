terraform {
  backend "azurerm" {
    resource_group_name  = "terraform041_state_rg"
    storage_account_name = "tfstate041storage"
    container_name       = "tfstate"
    key                  = "stage1.terraform.tfstate"
  }
}