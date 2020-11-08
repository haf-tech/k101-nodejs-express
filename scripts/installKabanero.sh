#!/bin/sh

# Install and configure Kabanero into an OpenShift Cluster 4.x

export K_VERSION=0.9.2

curl -s -L https://github.com/kabanero-io/kabanero-operator/releases/download/${K_VERSION}/install.sh -O && chmod +x install.sh

ENABLE_KAPPNAV=yes ./install.sh

#curl -L https://github.com/kabanero-io/kabanero-operator/releases/download/${K_VERSION}/default.yaml -O
#oc apply -n kabanero -f default.yaml

# apply the custom Kabanero CR with CRW and Event Pipelines, using 0.9
oc apply -n kabanero -f kabanero-events-default.yaml