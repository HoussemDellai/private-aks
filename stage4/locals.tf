locals {
  aks_name               = "${var.prefix}-aks"
  aks_rg                 = "${var.prefix}-aks-rg"
  aks_nodes_rg           = "${var.prefix}-aks-nodes-rg"
  storage_identity_name  = "${var.prefix}-storage-identity"
  storage_name           = "${var.prefix}storage"
  storage_namespace      = "storage"
  storage_identity_selector = "${var.prefix}-storage-identity-selector"
  keyvault_identity_name = "${var.prefix}-keyvault-identity"
  keyvault_name          = "${var.prefix}keyvault"
  keyvault_namespace     = "keyvault"
  keyvault_identity_selector = "${var.prefix}-keyvault-identity-selector"

  # aks_name       = "${var.aks_name != "" ? var.aks_name : "${var.prefix}-aks"}"
}