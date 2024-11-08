# Set environment variables
$OC = "C:\OpenShift\oc.exe"
$KUBECONFIG = "C:\OpenShift\kubeconfig"
$MIRROR_YAML_LOCATION="C:\OpenShift\"
$BYPASS_TLS = "true"

# Authenticate to the cluster
Write-Output "Authenticating to the cluster as ""$($(& $OC whoami --kubeconfig $KUBECONFIG --insecure-skip-tls-verify=$BYPASS_TLS))"""

# Apply the Catalogue Source and ICSP files
Write-Output "Applying the Catalogue Source and ICSP files:"
& $OC patch OperatorHub cluster --type json --patch '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]' --kubeconfig $KUBECONFIG --insecure-skip-tls-verify=$BYPASS_TLS
& $OC apply -f $MIRROR_YAML_LOCATION\catalogSource-cs-redhat-operator-index.yaml --kubeconfig $KUBECONFIG --insecure-skip-tls-verify=$BYPASS_TLS
& $OC apply -f $MIRROR_YAML_LOCATION\imageContentSourcePolicy.yaml --kubeconfig $KUBECONFIG --insecure-skip-tls-verify=$BYPASS_TLS
Write-Output ""

# Prepare OpenShift GitOps to run with ClusterAdmin privileges
Write-Output "Preparing OpenShift GitOps to run with ClusterAdmin privileges"
& $OC apply -f crb-cluster-admin-openshift-gitops-argocd-application-controller.yaml --kubeconfig $KUBECONFIG --insecure-skip-tls-verify=$BYPASS_TLS
Write-Output ""

# Install the operator
Write-Output "Installing the operator"
& $OC apply -f gitops-subscription.yaml --kubeconfig $KUBECONFIG --insecure-skip-tls-verify=$BYPASS_TLS
Write-Output ""

# Wait for the operator to install
Write-Output "Waiting for the operator to install"
while ($true) {
    $OperatorName = & $OC -n openshift-gitops get csv --kubeconfig $KUBECONFIG --insecure-skip-tls-verify=$BYPASS_TLS -o json | ConvertFrom-Json | ForEach-Object { $_.items | Where-Object { $_.metadata.name -match "openshift-gitops" } | Select-Object -ExpandProperty "metadata" | Select-Object -ExpandProperty "name" } 
    $OperatorStatus = & $OC -n openshift-gitops get csv $OperatorName --kubeconfig $KUBECONFIG --insecure-skip-tls-verify=$BYPASS_TLS -o jsonpath='{.status.phase}'
    Write-Output $OperatorStatus
    if ($OperatorStatus -eq "Succeeded") {
        break
    }
    Start-Sleep -Seconds 5
}

Write-Output ""
Write-Output "Creating the 'Application of Applications'"
& $OC apply -f gitops-application.yaml --kubeconfig $KUBECONFIG --insecure-skip-tls-verify=$BYPASS_TLS
