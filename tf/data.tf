# data "azurerm_container_registry" "acr" {
#   name                = "testacr"
#   resource_group_name = "test"
# }

data "azurerm_kubernetes_service_versions" "current" {
  location        = "West Europe"
  include_preview = false
}