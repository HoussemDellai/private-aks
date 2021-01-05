resource "helm_release" "storage_pod_identity_binding" {
  name             = "storage-pod-identity-binding"
  chart            = "./pod_identity_chart"
  namespace        = local.storage_namespace
  create_namespace = true

  set {
    name  = "namespace"
    value = local.storage_namespace
  }

  set {
    name  = "identityName"
    value = local.storage_identity_name
  }

  set {
    name  = "podIdentitySelector"
    value = "${local.storage_identity_name}-selector"
  }

  set {
    name  = "identityId"
    value = data.azurerm_user_assigned_identity.storage.id
  }

  set {
    name  = "identityClientId"
    value = data.azurerm_user_assigned_identity.storage.client_id
  }
}