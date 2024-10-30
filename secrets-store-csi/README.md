# Secrets Store CSI

https://www.redhat.com/en/blog/a-guide-to-integrating-azure-key-vault-with-an-azure-red-hat-openshift-cluster

## Keyvault

```
AKV_NAME=craig-vault-oct28
az keyvault create --name $AKV_NAME --resource-group $RESOURCEGROUP
```

Apply RBAC

`az role assignment create --role "Key Vault Adnministrator" --assignee "crscott@redhat.com" --scope $AKV_NAME`

## Create a secret

`az keyvault secret set --vault-name $AKV_NAME --name "postgres-user" --value '{"username": "postgres", "password": "randomstring"}'`

## RBAC

Create the service principal for the secret and set the policy for it.

```
export SERVICE_PRINCIPAL_CLIENT_SECRET="$(az ad sp create-for-rbac --name http://$AKV_NAME --query 'password' -otsv)"
export SERVICE_PRINCIPAL_CLIENT_ID="$(az ad sp list --display-name http://$AKV_NAME --query '[0].appId' -otsv)"
az keyvault set-policy -n ${AKV_NAME} --secret-permissions get --spn ${SERVICE_PRINCIPAL_CLIENT_ID}
```  

Noting that in demo.redhat.com, I can;t create a SP.  So:

```
export CLIENT_SECRET=<existing value>
export CLIENT_ID=<existing value>
az keyvault set-policy -n ${AKV_NAME} --secret-permissions get --spn ${CLIENT_ID}
```

or if --enable-rbac-authorization is in place on the vaule

```
az role assignment create --assignee ${CLIENT_ID} \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.KeyVault/vaults/${AKV_NAME}
```

## Secret

```
oc -n keycloak create secret generic secrets-store-creds \
  --from-literal clientid=${CLIENT_ID} \
  --from-literal clientsecret=${CLIENT_SECRET}
oc -n keycloak label secret \
  secrets-store-creds secrets-store.csi.k8s.io/used=true
```  

## Secret provider class

cat <<EOF | oc apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvname
  namespace: keycloak
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "false"
    userAssignedIdentityID: ""
    keyvaultName: "${AKV_NAME}"
    objects: |
      array:
        - |
          objectName: postgres-user
          objectType: secret
          objectVersion: ""
    tenantId: "${TENANT_ID}"
EOF    

## Allowing privileged pods

```
oc -n keycloak create serviceaccount keycloak-privileged-sa
oc -n keycloak adm policy add-scc-to-user privileged -z keycloak-privileged-sa
oc label namespace keycloak pod-security.kubernetes.io/enforce=privileged
```
