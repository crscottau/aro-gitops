# Set environment variables
$KUBECONFIG = "C:\OpenShift\kubeconfig"
$MIRROR_YAML_LOCATION="C:\OpenShift\mirror"
$BYPASS_TLS = "true"

# Define OpenShift command with kubeconfig and bypass TLS options
$OC = "C:\OpenShift\oc --kubeconfig $KUBECONFIG --insecure-skip-tls-verify=$BYPASS_TLS"

# Authenticate to the cluster
Write-Output "Authenticating to the cluster as ""$($(& $OC whoami))"""

# Apply the Catalogue Source and ICSP files
Write-Output "Applying the Catalogue Source and ICSP files:"
& $OC patch OperatorHub cluster --type json --patch '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
& $OC apply -f $MIRROR_YAML_LOCATION\catalogSource-cs-redhat-operator-index.yaml
& $OC apply -f $MIRROR_YAML_LOCATION\imageContentSourcePolicy.yaml
Write-Output ""

# Prepare OpenShift GitOps to run with ClusterAdmin privileges
Write-Output "Preparing OpenShift GitOps to run with ClusterAdmin privileges"
& $OC apply -f crb-cluster-admin-openshift-gitops-argocd-application-controller.yaml
Write-Output ""

# Install the operator
Write-Output "Installing the operator"
& $OC apply -f gitops-subscription.yaml
Write-Output ""

# Wait for the operator to install
Write-Output "Waiting for the operator to install"
while ($true) {
    $OperatorName = & oc -n openshift-gitops get csv -o json | ConvertFrom-Json | ForEach-Object { $_.items | Where-Object { $_.metadata.name -match "openshift-gitops" } | Select-Object -ExpandProperty "metadata" | Select-Object -ExpandProperty "name" }
    $OperatorStatus = & oc -n openshift-gitops get csv $OperatorName -o jsonpath='{.status.phase}'
    Write-Output $OperatorStatus
    if ($OperatorStatus -eq "Succeeded") {
        break
    }
    Start-Sleep -Seconds 5
}

Write-Output ""
Write-Output "Creating the 'Application of Applications'"
& $OC apply -f gitops-application.yaml
