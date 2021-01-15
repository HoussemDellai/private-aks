terraform {
  backend "azurerm" {
    resource_group_name  = "terraform037_state_rg"
    storage_account_name = "tfstate037storage"
    container_name       = "tfstate"
    key                  = "stage4.terraform.tfstate"
  }
}