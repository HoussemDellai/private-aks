$storage_account_name="demo023storage"
$container_name="demo023-container"
$namespace="storage"
$pod_identity_selector="id4storage-selector"

# testing for Storage Account
echo "Deploying an Nginx Pod for testing..."
@"
kind: Pod
apiVersion: v1
metadata:
  name: nginx
  namespace: $($namespace)
  labels:
    aadpodidbinding: $($pod_identity_selector)
spec:
  containers:
    - name: nginx
      image: nginx
      args: [/bin/sh, -c, 'i=0; while true; do sleep 10; done']
"@ | kubectl apply -f -

echo "Validating the pod has access to the Storage Account..."
kubectl exec -it nginx -n $namespace -- /bin/sh 
# az login --identity
# az storage blob list -o table -c $container_name --account-name $storage_account_name --account-key 'VxOMmo7/O7GwSNz3kAQG/lHEwxxxdn1F4PnoJa7/fVgbincAGqUWldYg0xmtUmUU0aOhmQfxhtwMxIRQEneOdA=='


curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true -s
curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com' -H Metadata:true -s


curl "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://${storage_account_name}.blob.core.windows.net" -H Metadata:true -s


response=$(curl "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://${storage_account_name}.blob.core.windows.net" -H Metadata:true -s)
access_token=$(echo $response | python -c 'import sys, json; print (json.load(sys.stdin)["access_token"])')
echo The managed identities for Azure resources access token is $access_token


apk add --update jq

apt-get update
apt-get install jq

#!/bin/sh

storage_account_name="demo023storage"
container_name="demo023-container"

RESOURCE="https://${storage_account_name}.blob.core.windows.net"
SERVICE_URL="https://${storage_account_name}.blob.core.windows.net/${container_name}/sample-file.sh"

echo "RESOURCE: ${RESOURCE}"
echo "SERVICE_URL: ${SERVICE_URL}"

jwt=$(curl -sS http://169.254.169.254/metadata/identity/oauth2/token/?resource=$RESOURCE)
echo "Full token:  $jwt"
token=$(echo $jwt | jq -r '.access_token')
echo "Access token:  $token"
curl -v -H 'x-ms-version: 2020-04-08' -H 'Accept: application/json' -H "Authorization: Bearer ${token}" $SERVICE_URL