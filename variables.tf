variable "prefix" {
  type        = string
  description = "A prefix used for all resources in this example"
}

variable "location" {
  type        = string
  description = "The Azure Region in which all resources in this example should be provisioned"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
}

variable "default_node_count" {
  description = "default node count for system node pool"
}

variable "acr_name" {
  type        = string
  description = "ACR name"
}

variable "keyvault_name" {
  type        = string
  description = "Name for the Key Vault instance"
}

variable "db_admin_login" {
  type        = string
  description = "Database secret admin login"
}

variable "db_admin_password" {
  type        = string
  description = "Database secret admin password"
}

variable "storage_name" {
  type        = string
  description = "The name of the Storage Account."
}