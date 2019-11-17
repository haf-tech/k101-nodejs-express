#!/bin/sh

namespace=kabanero
APP_REPO=https://github.com/haf-tech/k101-nodejs-express.git
REPO_BRANCH=master
DOCKER_IMAGE="docker-registry.default.svc:5000/demo-express/k101-nodejs-express:v0.1"

cat <<EOF | oc -n ${namespace} apply -f -
apiVersion: v1
items:
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: docker-image
  spec:
    params:
    - name: url
      value: ${DOCKER_IMAGE}
    type: image
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: git-source
  spec:
    params:
    - name: revision
      value: ${REPO_BRANCH}
    - name: url
      value: ${APP_REPO}
    type: git
kind: List
EOF

oc get pipelineresource -n kabanero

cat <<EOF | oc -n ${namespace} apply -f -
apiVersion: tekton.dev/v1alpha1
kind: PipelineRun
metadata:
  name: nodejs-express-build-deploy-pipeline-run
  namespace: kabanero
spec:
  pipelineRef:
    name: nodejs-express-build-deploy-pipeline
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
