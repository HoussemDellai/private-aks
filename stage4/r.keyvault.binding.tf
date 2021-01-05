resource "helm_release" "keyvault_pod_identity_binding" {
  name             = "keyvault-pod-identity-binding"
  chart            = "./pod_identity_chart"
  namespace        = local.keyvault_namespace
  create_namespace = true

  set {
    name  = "namespace"
    value = local.keyvault_namespace
  }

  set {
    name  = "identityName"
    value = local.keyvault_identity_name
  }

  set {
    name  = "podIdentitySelector"
    value = local.keyvault_identity_selector
  }

  set {
    name  = "identityId"
    value = data.azurerm_user_assigned_identity.keyvault.id
  }

  set {
    name  = "identityClientId"
    value = data.azurerm_user_assigned_identity.keyvault.client_id
  }
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