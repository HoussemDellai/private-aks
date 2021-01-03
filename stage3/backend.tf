terraform {
  backend "azurerm" {
    resource_group_name  = "terraform_state_rg"
    storage_account_name = "tfstate021storage"
    container_name       = "tfstate"
    key                  = "stage3.terraform.tfstate"
  }
}