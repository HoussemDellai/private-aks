resource "helm_release" "pod_identity_binding" {
  name = "pod-identity-binding"
  chart = "./pod_identity_chart"
  namespace  = "storage"
  create_namespace = true

  set {
    name  = "namespace"
    value = "storage"
  }

  set {
    name  = "identityName"
    value = "storage-identity"
  }

  set {
    name  = "podIdentitySelector"
    value = "id4storage-selector"
  }

  set {
    name  = "identityId"
    value = data.azurerm_user_assigned_identity.identity.id
  }

  set {
    name  = "identityClientId"
    value = data.azurerm_user_assigned_identity.identity.client_id
  }
}

data "azurerm_user_assigned_identity" "identity" {
  name                = local.identity_name # "storage-identity"
  resource_group_name = "MC_demo0051-aks-rg_demo0051-aks_westeurope"
}

locals {
  aks_name       = "${var.prefix}-aks"
  identity_name  = "${var.prefix}-identity"
  # node_resource_group = 
  # aks_rg         = "${var.prefix}-aks-rg"
  # aks_name       = "${var.aks_name != "" ? var.aks_name : "${var.prefix}-aks"}"
}

# data "template_file" "yaml_template" {
#   template = "${file("azure_identity.yaml")}"
# }
# 
# resource "null_resource" "yaml_deployment" {
#   triggers = {
#     manifest_sha1 = "${sha1("${data.template_file.yaml_template.rendered}")}"
#   }
# 
#   provisioner "local-exec" {
#     command = "kubectl apply -f -<<EOF\n${data.template_file.yaml_template.rendered}\nEOF"
#   }
# }