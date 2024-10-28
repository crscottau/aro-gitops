Create a certificate and a secret

https://docs.redhat.com/en/documentation/red_hat_build_of_keycloak/22.0/html/operator_guide/basic-deployment-#basic-deployment-hostname

`openssl req -subj '/CN=keycloak.apps.xbpf9.azure.redhatworkshops.io/O=azure.redhatworkshops.io/C=AU' -newkey rsa:2048 -nodes -keyout keycloak-key.pem -x509 -days 365 -out keycloak-cert.pem`

`oc -n keycloak create secret tls keycloak-tls-secret --cert keycloak-cert.pem --key keycloak-key.pem`
