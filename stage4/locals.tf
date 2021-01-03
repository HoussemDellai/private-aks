locals {
  aks_name      = "${var.prefix}-aks"
  identity_name = "${var.prefix}-identity"
  storage_name  = "${var.prefix}storage"
  aks_nodes_rg  = "${var.prefix}-aks-nodes-rg"
  # aks_name       = "${var.aks_name != "" ? var.aks_name : "${var.prefix}-aks"}"
}