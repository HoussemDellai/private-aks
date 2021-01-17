az login --identity

$ARM_USE_MSI="true"

$ARM_SUBSCRIPTION_ID=$(az account show --query id)

$ARM_TENANT_ID=$(az account show --query tenantId)

terraform init

terraform plan -out tfplan

terraform apply tfplan

# When working authentication using Managed Identity (MSI) in terraform, 
# we can either use the following backend and provider block:
# 
# provider "azurerm" {
#     features {}
#   
#     use_msi = true
#     subscription_id      = "7b1f7584-000000000000000000000000000"
#     tenant_id            = "558506eb-000000000000000000000000000"
# }
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "terraform041_state_rg"
#     storage_account_name = "tfstate041storage"
#     container_name       = "tfstate"
#     key                  = "stage3.terraform.tfstate"
# 
#     use_msi              = true
#     subscription_id      = "7b1f7584-000000000000000000000000000"
#     tenant_id            = "558506eb-000000000000000000000000000"
#   }
# }
#
# Or we can also use environment variables like following,
# which is better to hide the value from tf files:
#
# az login --identity
#
# $ARM_USE_MSI="true"
# 
# $ARM_SUBSCRIPTION_ID=$(az account show --query id)
# 
# $ARM_TENANT_ID=$(az account show --query tenantId)
