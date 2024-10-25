# OpenShift Logging

Logging to LAW

https://cloud.redhat.com/experts/aro/clf-to-azure/

## Azure setup

Prepare

```
export AZR_RESOURCE_LOCATION=eastasia
export AZR_RESOURCE_GROUP=openenv-r54br
# this value must be unique
export AZR_LOG_APP_NAME=craig-law
```

Create the LAW

```
az extension add --name log-analytics
az monitor log-analytics workspace create \
 -g $AZR_RESOURCE_GROUP -n $AZR_LOG_APP_NAME \
 -l $AZR_RESOURCE_LOCATION
 ```

Get details

 ```
 WORKSPACE_ID=$(az monitor log-analytics workspace show \
 -g $AZR_RESOURCE_GROUP -n $AZR_LOG_APP_NAME \
 --query customerId -o tsv)
SHARED_KEY=$(az monitor log-analytics workspace get-shared-keys \
 -g $AZR_RESOURCE_GROUP -n $AZR_LOG_APP_NAME \
 --query primarySharedKey -o tsv)
 ```

 ### OCP

 Create a secret:
 `oc -n openshift-logging create secret generic azure-monitor-shared-key --from-literal=shared_key=${SHARED_KEY}`

 Then create the CLF, see code.

 !!! Need to update the WORKSPACE_ID