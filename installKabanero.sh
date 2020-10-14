#!/bin/sh

# Install Kabanero into an OpenShift Cluster 4.x

export K_VERSION=0.4.0

curl -s -L https://github.com/kabanero-io/kabanero-operator/releases/download/${K_VERSION}/install.sh -O && chmod +x install.sh

ENABLE_KAPPNAV=yes ./install.sh

curl https://raw.githubusercontent.com/kabanero-io/kabanero-operator/${K_VERSION}/config/samples/default.yaml -O

oc apply -n kabanero -f default.yaml