$storage_account_name="demo0051storacc"
$namespace="storage"
$pod_identity_selector="id4storage-selector"

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