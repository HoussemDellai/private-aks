variable "prefix" {
  type        = string
  description = "A prefix used for all resources in this example"
}

# variable "location" {
#   type        = string
#   description = "The Azure Region in which all resources in this example should be provisioned"
# }
# 
# variable "kubernetes_version" {
#   type        = string
#   description = "Kubernetes version"
# }
# 
# variable "default_node_count" {
#   description = "default node count for system node pool"
# }
# 
# variable "db_admin_login" {
#   type        = string
#   description = "Database secret admin login stored in Keyvault"
# }
# 
# variable "db_admin_password" {
#   type        = string
#   description = "Database secret admin password stored in Keyvault"
# }
# 
# variable "aks_name" {
#   type        = string
#   description = "AKS name"
# }
# 
# variable "acr_name" {
#   type        = string
#   description = "ACR name"
# }
# 
# variable "keyvault_name" {
#   type        = string
#   description = "Name for the Key Vault instance"
# }
# 
# 
# variable "storage_name" {
#   type        = string
#   description = "The name of the Storage Account."
# }
# 
# variable "identity_name" {
#   type        = string
#   description = "The name of the Identity Storage Account."
# }
# 
# variable "allowed_ips" {
#   type    = list(string)
#   default = ["141.101.69.109/32"]
# }