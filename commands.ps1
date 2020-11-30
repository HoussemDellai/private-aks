echo "Setting up the variables..."
$subscriptionId = (az account show | ConvertFrom-Json).id
$tenantId = (az account show | ConvertFrom-Json).tenantId
$location = "westeurope"
$resourceGroupName = "demo03-rg"
$aksName = "demo03-aks"
$keyVaultName = "privatekv03"
$secret1Name = "DatabaseLogin"
$secret2Name = "DatabasePassword"
$secret1Alias = "DATABASE_LOGIN"
$secret2Alias = "DATABASE_PASSWORD" 
$identityName = "identity-aks-kv"
$identitySelector = "azure-kv"
$secretProviderClassName = "secret-provider-kv"

$aks = az aks show -n $aksName -g $resourceGroupName | ConvertFrom-Json

echo "Creating Key Vault..."
$keyVault = az keyvault create -n $keyVaultName -g $resourceGroupName -l $location --enable-soft-delete true --retention-days 7 | ConvertFrom-Json
# $keyVault = az keyvault show -n $keyVaultName -g $resourceGroupName  | ConvertFrom-Json

echo "Creating Secrets in Key Vault..."
az keyvault secret set --name $secret1Name --value "Houssem" --vault-name $keyVaultName
az keyvault secret set --name $secret2Name --value "P@ssword123456" --vault-name $keyVaultName

echo "Installing Secrets Store CSI Driver using Helm..."
kubectl create ns csi-driver
echo "Installing Secrets Store CSI Driver with Azure Key Vault Provider..."
helm repo add csi-secrets-store-provider-azure https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts
helm install csi-azure csi-secrets-store-provider-azure/csi-secrets-store-provider-azure --namespace csi-driver
sleep 2
kubectl get pods -n csi-driver

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
    resourceGroup: $resourceGroupName
    subscriptionId: $subscriptionId
    tenantId: $tenantId
"@
$secretProviderKV | kubectl create -f -

az role assignment create --role "Managed Identity Operator" --assignee $aks.identityProfile.kubeletidentity.clientId --scope /subscriptions/$subscriptionId/resourcegroups/$($aks.nodeResourceGroup)
az role assignment create --role "Virtual Machine Contributor" --assignee $aks.identityProfile.kubeletidentity.clientId --scope /subscriptions/$subscriptionId/resourcegroups/$($aks.nodeResourceGroup)

echo "Installing AAD Pod Identity into AKS..."
helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
helm install pod-identity aad-pod-identity/aad-pod-identity
# kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml
kubectl get pods

echo "Retrieving the existing Azure Identity..."
$existingIdentity = az resource list -g $aks.nodeResourceGroup --query "[?contains(type, 'Microsoft.ManagedIdentity/userAssignedIdentities')]"  | ConvertFrom-Json
$identity = az identity show -n $existingIdentity.name -g $existingIdentity.resourceGroup | ConvertFrom-Json

echo "Assigning Reader Role to new Identity for Key Vault..."
az role assignment create --role "Reader" --assignee $identity.principalId --scope $keyVault.id

echo "Setting policy to access secrets in Key Vault..."
az keyvault set-policy -n $keyVaultName --secret-permissions get --spn $identity.clientId

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

echo "Deploying a Nginx Pod for testing..."
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
