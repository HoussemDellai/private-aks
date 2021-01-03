#--------------------------------------------------------------------------------
# Secret Store CSI Driver for Key Vault
#--------------------------------------------------------------------------------

resource "helm_release" "csi_azure_release" {
  name             = "csi-keyvault"
  repository       = "https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts"
  chart            = "csi-secrets-store-provider-azure"
  namespace        = "csi-driver"
  create_namespace = true
}

resource "helm_release" "pod_identity_release" {
  name             = "pod-identity"
  repository       = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  chart            = "aad-pod-identity"
  namespace        = "default"
  create_namespace = true
}