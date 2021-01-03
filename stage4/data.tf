data "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  resource_group_name = "${var.prefix}-aks-rg"
}

data "azurerm_user_assigned_identity" "identity" {
  name                = local.identity_name
  resource_group_name = local.aks_nodes_rg
}