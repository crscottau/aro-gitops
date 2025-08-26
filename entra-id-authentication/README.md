# OpenID authentication with Entra ID

## Application

An OpenID _application_ needs to be created in Entra ID to define the OpenSHift clusters and set the allowed callback URL. The callback URL is the OpenShift authentication route. A client ID and client secret need to be generated to allow OpenSHift to authenticate with Entra ID.

Group claims also need to be created in the application to pass through to ARO.

[https://learn.microsoft.com/en-us/azure/openshift/configure-azure-ad-ui]

[https://cloud.redhat.com/experts/idp/group-claims/aro/]
