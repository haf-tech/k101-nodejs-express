#!/bin/sh

# configure the Kabanero Webhook using event pipelines/operator
#
# creates a secret for the GitHub access and register this one to the serviceaccount kabanero-pipeline
# Generate PAT: https://github.com/settings/tokens
# Also creates all resources for handling Webhook events centrally from GitHub (Mediator, Connection)

gitUserId=$1
gitPAT=$2

randomWebhookSecret=$(openssl rand -hex 16)
tektonDashboardUrl=$(oc get route -n tekton-pipelines tekton-dashboard --template='http://{{.spec.host}}')
registryBaseUrl="image-registry.openshift-image-registry.svc:5000/demo-kabanero"

cat << EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: personal-github-secret
  namespace: kabanero
  annotations:
    tekton.dev/git-0: https://github.com
type: kubernetes.io/basic-auth
stringData:
  username: $gitUserId
  password:  $gitPAT
EOF

# Patch serviceaccount kabanero-pipeline and add the secret
oc get sa kabanero-pipeline -n kabanero -o yaml 

oc patch sa kabanero-pipeline -n kabanero --type='json' -p='[{"op": "add", "path": "/secrets/-", "value":{"name": "personal-github-secret"}}]'

# Create secret for WebHook
cat << EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: personal-webhook-secret
  namespace: kabanero
stringData:
  secretToken: $randomWebhookSecret
EOF

# Create the EventMediator
cat << EOF | oc apply -f -
apiVersion: events.kabanero.io/v1alpha1
kind: EventMediator
metadata:
  name: webhook
  namespace: kabanero
spec:
  createListener: true
  createRoute: true
  repositories:
    - github:
        secret: personal-github-secret
        webhookSecret: personal-webhook-secret
  mediations:
    - name: webhook
      selector:
        repositoryType:
          newVariable: body.webhooks-appsody-config
          file: .appsody-config.yaml
      variables:
        - name: body.webhooks-tekton-target-namespace
          value: kabanero
        - name: body.webhooks-tekton-service-account
          value: kabanero-pipeline
        - name: body.webhooks-tekton-docker-registry
          value: $registryBaseUrl
        - name: body.webhooks-tekton-ssl-verify
          value: "false"
        - name: body.webhooks-tekton-insecure-skip-tls-verify
          value: "true"
        - name: body.webhooks-tekton-local-deploy
          value: "true"
        - name: body.webhooks-tekton-monitor-dashboard-url
          value: $tektonDashboardUrl
      sendTo: [ "dest" ]
      body:
        - = : "sendEvent(dest, body, header)"
EOF

# Create EventConnections
cat << EOF | oc apply -f -
apiVersion: events.kabanero.io/v1alpha1
kind: EventConnections
metadata:
  name: connections
  namespace: kabanero
spec:
  connections:
    - from:
        mediator:
            name: webhook
            mediation: webhook
            destination: dest
      to:
        - https:
            - urlExpression:  body["webhooks-kabanero-tekton-listener"]
              insecure: true

EOF

echo "######################################"
echo "Webhook Secret: $randomWebhookSecret"
echo "Webhook Payload URL: $(oc get route webhook -n kabanero --template='https://{{.spec.host}}')"
echo ""
echo "Instruction for GitHub"
echo "Select your Organization > Settings > Webhook: Add webhook"
echo "Payload URL: $(oc get route webhook -n kabanero --template='https://{{.spec.host}}')"
echo "Content type: application/json"
echo "Secret: $randomWebhookSecret"
echo "SSL verification: disable"
echo "Which events would you like to trigger this webhook?: everything"
echo "Press Add webhook."
echo "######################################"