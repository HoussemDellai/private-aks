# data "azurerm_container_registry" "acr" {
#   name                = "testacr"
#   resource_group_name = "test"
# }

// data "azurerm_resource_group" "aks" {
//   name = local.aks_rg
// }

data "azurerm_client_config" "current" {
}

data "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  resource_group_name = local.aks_rg # data.azurerm_resource_group.aks.name
}

// data "azurerm_kubernetes_cluster" "aks" {
//   name                = local.aks_name
//   resource_group_name = local.aks_rg
// }

data "azurerm_kubernetes_service_versions" "current" {
  location        = local.location
  include_preview = false
}

data "http" "machine_ip" {
  url = "http://ifconfig.me"
}