resource "helm_release" "pod_identity" {
  name = "pod-identity-release"
  # repository = "https://charts.bitnami.com/bitnami"
  chart = "./pod_identity_chart"
  # version    = "6.0.1"

  //   values = [
  //     "${file("values.yaml")}"
  //   ]

  set {
    name  = "namespace"
    value = "storage"
  }

  set {
    name  = "identityName"
    value = "id4storage"
  }

  set {
    name  = "podLabelSelector"
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
  name                = "storage-identity"
  resource_group_name = "MC_demo0051-aks-rg_demo0051-aks_westeurope"
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