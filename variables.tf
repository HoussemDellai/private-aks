variable "prefix" {
  description = "A prefix used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be provisioned"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
}

variable "default_node_count" {
  description = "default node count for system node pool"
}

variable "acr_name" {
  description = "ACR name"
}

variable "keyvault_name" {
  description = "Name for the Key Vault instance"
}

variable "db_admin_login" {
  description = "Database secret admin login"
}

variable "db_admin_password" {
  description = "Database secret admin password"
}

// variable "node_rg_name" {
//   description = "The name of the Resource Group where the Kubernetes Nodes should exist. Changing this forces a new resource to be created."
// }