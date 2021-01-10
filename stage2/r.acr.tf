#--------------------------------------------------------------------------------
# ACR (public)
#--------------------------------------------------------------------------------

resource "azurerm_resource_group" "acr" {
  name     = local.acr_rg
  location = local.location
}

resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.acr.name
  location            = local.location
  sku                 = "Standard"
  admin_enabled       = false
}

resource "azurerm_role_assignment" "role_acrpull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}