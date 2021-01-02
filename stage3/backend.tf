terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate0105"
    container_name       = "tfstate"
    key                  = "stage3.terraform.tfstate"
  }
}