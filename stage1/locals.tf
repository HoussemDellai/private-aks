#--------------------------------------------------------------------------------
# Local variables
#--------------------------------------------------------------------------------

locals {
  location       = "westeurope"
  aks_name       = "${var.prefix}-aks"
  dns_prefix     = "${var.prefix}-dns"
  acr_name       = "${var.prefix}acr"
  keyvault_name  = "${var.prefix}keyvault"
  storage_name   = "${var.prefix}storage"
  identity_name  = "${var.prefix}-identity"
  vnet_name      = "${var.prefix}-vnet"
  container_name = "${var.prefix}-container"
  aks_rg         = "${var.prefix}-aks-rg"
  aks_nodes_rg   = "${var.prefix}-aks-nodes-rg"
  acr_rg         = "${var.prefix}-acr-rg"
  bastion_rg     = "${var.prefix}-bastion-rg"
  vm_rg          = "${var.prefix}-vm-rg"
  storage_rg     = "${var.prefix}-storage-rg"
  keyvault_rg    = "${var.prefix}-keyvault-rg"
  # aks_name       = "${var.aks_name != "" ? var.aks_name : "${var.prefix}-aks"}"
}