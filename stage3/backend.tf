terraform {
  backend "azurerm" {
    resource_group_name  = "terraform041_state_rg"
    storage_account_name = "tfstate041storage"
    container_name       = "tfstate"
    key                  = "stage3.terraform.tfstate"

    # use_msi              = true
    # subscription_id      = "7b1f7584-000000000000000000000000000"
    # tenant_id            = "558506eb-000000000000000000000000000"
  }
}