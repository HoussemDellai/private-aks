echo "Setting up the variables..."
$subscriptionId = (az account show | ConvertFrom-Json).id
$tenantId = (az account show | ConvertFrom-Json).tenantId
$location = "westeurope"
$aksRg = "demo05-aks-rg"
$kvRg = "demo05-kv-rg"
$aksName = "demo05-aks"
$keyVaultName = "privatekv05"
$secret1Name = "DatabaseLogin"
$secret2Name = "DatabasePassword"
$secret1Alias = "DATABASE_LOGIN"
$secret2Alias = "DATABASE_PASSWORD" 
$identityName = "identity-aks-kv"
$identitySelector = "azure-kv"
$secretProviderClassName = "secret-provider-kv"

$aks = az aks show -n $aksName -g $aksRg | ConvertFrom-Json

echo "Getting Key Vault..."
$keyVault = az keyvault show -n $keyVaultName -g $kvRg  | ConvertFrom-Json

# echo "Installing Secrets Store CSI Driver using Helm..."
# kubectl create ns csi-driver
# echo "Installing Secrets Store CSI Driver with Azure Key Vault Provider..."
# helm repo add csi-secrets-store-provider-azure https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts
# helm install csi-azure csi-secrets-store-provider-azure/csi-secrets-store-provider-azure --namespace csi-driver
# sleep 2
# kubectl get pods -n csi-driver

echo "Using the Azure Key Vault Provider..."
$secretProviderKV = @"
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: $($secretProviderClassName)
spec:
  provider: azure
  parameters:
    usePodIdentity: "true"
    useVMManagedIdentity: "false"
    userAssignedIdentityID: ""
    keyvaultName: $keyVaultName
    cloudName: AzurePublicCloud
    objects:  |
      array:
        - |
          objectName: $secret1Name
          objectAlias: $secret1Alias
          objectType: secret
          objectVersion: ""
        - |
          objectName: $secret2Name
          objectAlias: $secret2Alias
          objectType: secret
          objectVersion: ""
    tenantId: $tenantId
"@
$secretProviderKV | kubectl apply -f -

# echo "Installing AAD Pod Identity into AKS..."
# helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
# helm install pod-identity aad-pod-identity/aad-pod-identity
# # kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml
# kubectl get pods

echo "Retrieving the existing Azure Identity..."
$existingIdentity = az identity list --query "[?contains(name, '-agentpool')]" | ConvertFrom-Json
# $existingIdentity = az resource list -g $aks.nodeResourceGroup --query "[?contains(type, 'Microsoft.ManagedIdentity/userAssignedIdentities')]"  | ConvertFrom-Json
$identity = az identity show -n $existingIdentity.name -g $existingIdentity.resourceGroup | ConvertFrom-Json

echo "Adding AzureIdentity and AzureIdentityBinding..."
$aadPodIdentityAndBinding = @"
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentity
metadata:
  name: $($identityName)
spec:
  type: 0
  resourceID: $($identity.id)
  clientID: $($identity.clientId)
---
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentityBinding
metadata:
  name: $($identityName)-binding
spec:
  azureIdentity: $($identityName)
  selector: $($identitySelector)
"@
$aadPodIdentityAndBinding | kubectl apply -f -

echo "Deploying an Nginx Pod for testing..."
$nginxPod = @"
kind: Pod
apiVersion: v1
metadata:
  name: nginx-secrets-store
  labels:
    aadpodidbinding: $($identitySelector)
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
      - name: secrets-store-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
  volumes:
    - name: secrets-store-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: $($secretProviderClassName)
"@
$nginxPod | kubectl apply -f -

sleep 20
kubectl get pods

echo "Validating the pod has access to the secrets from Key Vault..."
kubectl exec -it nginx-secrets-store -- ls /mnt/secrets-store/
kubectl exec -it nginx-secrets-store -- cat /mnt/secrets-store/DATABASE_LOGIN
kubectl exec -it nginx-secrets-store -- cat /mnt/secrets-store/$secret1Alias
kubectl exec -it nginx-secrets-store -- cat /mnt/secrets-store/DATABASE_PASSWORD
kubectl exec -it nginx-secrets-store -- cat /mnt/secrets-store/$secret2Alias

# testing for Key Vault with Pod Identity, without CSI Driver
# yet another option
echo "Deploying an Nginx Pod for testing..."
@"
kind: Pod
apiVersion: v1
metadata:
  name: azure-cli
  labels:
    aadpodidbinding: $($identitySelector)
spec:
  containers:
    - name: azure-cli
      image: mcr.microsoft.com/azure-cli
      args: [/bin/sh, -c, 'i=0; while true; do sleep 10; done']
"@ | kubectl apply -f -

echo "Validating the pod has access to the secrets from Key Vault..."
kubectl exec -it azure-cli -- /bin/sh 
az login --identity
az keyvault secret show --vault-name private0kv0051 --name DatabasePassword

#----------------------------------------------------------------------------------------

$storage_account_name = "demo0051storacc"
$identity_name="storage-identity"

$namespace="storage"
kubectl create namespace $namespace

$identity = az identity show -n $identity_name -g $aks.nodeResourceGroup | ConvertFrom-Json

$pod_identity_selector="$($identity_name)-selector"

@"
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentity
metadata:
  name: $($identity_name)
  namespace: $($namespace)
spec:
  type: 0
  resourceID: $($identity.id)
  clientID: $($identity.clientId)
---
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentityBinding
metadata:
  name: $($identity_name)-binding
  namespace: $($namespace)
spec:
  azureIdentity: $($identity_name)
  selector: $($pod_identity_selector)
"@ | kubectl apply -f -

# testing for Storage Account
echo "Deploying an Nginx Pod for testing..."
@"
kind: Pod
apiVersion: v1
metadata:
  name: storage-az-cli
  namespace: $($namespace)
  labels:
    aadpodidbinding: $($pod_identity_selector)
spec:
  containers:
    - name: azure-cli
      image: mcr.microsoft.com/azure-cli
      args: [/bin/sh, -c, 'i=0; while true; do sleep 10; done']
"@ | kubectl apply -f -

echo "Validating the pod has access to the Storage Account..."
kubectl exec -it storage-az-cli -n $namespace -- /bin/sh 
az login --identity
az storage blob list -o table -c data --account-name $storage_account_name --account-key 'ncnKtGDdIQmCSLkbfXYNGnwaXuGDOoGCKYmrmXLQY/R5lauPABgWKql9xXcwP6OuKAr83+DwBd+4NOUaTjaMqA=='
