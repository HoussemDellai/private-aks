data "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name
  resource_group_name = local.aks_nodes_rg
}

data "azurerm_user_assigned_identity" "storage" {
  name                = local.storage_identity_name
  resource_group_name = local.aks_nodes_rg
}

data "azurerm_user_assigned_identity" "keyvault" {
  name                = local.keyvault_identity_name
  resource_group_name = local.aks_nodes_rg
}