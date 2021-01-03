# data "azurerm_container_registry" "acr" {
#   name                = "testacr"
#   resource_group_name = "test"
# }

data "azurerm_kubernetes_service_versions" "current" {
  location        = "westeurope"
  include_preview = false
}

data "http" "machine_ip" {
  url = "http://ifconfig.me"
}