#!/usr/bin/env bash

export KUBECONFIG=/home/crscott/tmp/kubeconfig
export MIRROR_YAML_LOCATION=/home/crscott/tmp
export BYPASS_TLS=true

OC="oc --kubeconfig ${KUBECONFIG} --insecure-skip-tls-verify=${BYPASS_TLS}" 

echo Authenticating to the cluster as \"$(${OC} whoami)\"

echo Applying the Catalogue Source and ICSP files:
${OC} patch OperatorHub cluster --type json --patch '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
${OC} apply -f ${MIRROR_YAML_LOCATION}/catalogSource-cs-redhat-operator-index.yaml                             
${OC} apply -f ${MIRROR_YAML_LOCATION}/imageContentSourcePolicy.yaml
echo ""

echo Preparing OpenShift GitOps to run with ClusterAdmin privileges
${OC} apply -f crb-cluster-admin-openshift-gitops-argocd-application-controller.yaml
echo ""

echo Installing the operator
${OC} apply -f gitops-subscription.yaml
echo ""

echo Wait for the operator to install
while true
do
  OPERATOR_NAME=$(oc -n openshift-gitops get csv -o json | jq -r '.items[] | select(.metadata.name|contains ("openshift-gitops")) | .metadata.name')
  OPERATOR_STATUS=$(oc -n openshift-gitops get csv ${OPERATOR_NAME} -o jsonpath='{.status.phase}')
  echo $OPERATOR_STATUS
  if [ "$OPERATOR_STATUS" = "Succeeded" ]; then
    break
  fi
done

echo ""
echo Creating the "Application of Applications"
${OC} apply -f gitops-application.yaml