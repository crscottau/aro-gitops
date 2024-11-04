# Keycloak operator

## DB Secret

Create a secret that contains the Postgres database username and password:

`oc -n keycloak create secret generic keycloak-db-secret --from-literal=username=postgres --from-literal=password="2wsx#EDC"`

Create a secret that contains the Keycloak certificate and key

`oc -n keycloak create secret tls keycloak-tls-secret --cert keycloak-cert.pem --key keycloak-key.pem`