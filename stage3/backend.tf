terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate0105"
    container_name       = "tfstate"
    key                  = "stage3.terraform.tfstate"
  }
}

// data "terraform_remote_state" "stage1_state" {
//   backend = "azurerm"
//   config = {
//     storage_account_name = "tfstate0105"
//     container_name       = "tfstate"
//     key                  = "stage1.terraform.tfstate"
//   }
// }