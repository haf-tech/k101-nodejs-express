#!/bin/sh

namespace=kabanero
APP_REPO=https://github.com/haf-tech/k101-nodejs-express.git
REPO_BRANCH=master
DOCKER_IMAGE="image-registry.openshift-image-registry.svc:5000/demo-express/k101-nodejs-express:v0.1"


cat <<EOF | oc -n ${namespace} apply -f -
apiVersion: tekton.dev/v1alpha1
kind: PipelineRun
metadata:
  name: nodejs-express-build-deploy-pipeline-run-2
  namespace: kabanero
spec:
  pipelineRef:
    name: nodejs-express-build-push-deploy-pipeline
  resources:
  - name: git-source
    resourceRef:
      name: git-source
  - name: docker-image
    resourceRef:
      name: docker-image
  serviceAccount: kabanero-operator
  timeout: 60m
EOF
