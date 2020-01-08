#!/bin/sh

namespace=kabanero
APP_REPO=https://github.com/haf-tech/k101-nodejs-express.git
REPO_BRANCH=master
DOCKER_IMAGE="docker-registry.default.svc:5000/${PRJ_NAME}/k101-nodejs-express:v0.1"

cat <<EOF | oc -n ${namespace} apply -f -
apiVersion: v1
items:
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: ${PRJ_NAME}-docker-image
  spec:
    params:
    - name: url
      value: ${DOCKER_IMAGE}
    type: image
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: ${PRJ_NAME}-git-source
  spec:
    params:
    - name: revision
      value: ${REPO_BRANCH}
    - name: url
      value: ${APP_REPO}
    type: git
kind: List
EOF

oc get pipelineresource -n ${namespace}

cat <<EOF | oc -n ${namespace} apply -f -
apiVersion: tekton.dev/v1alpha1
kind: PipelineRun
metadata:
  name: ${PRJ_NAME}-nodejs-express-build-push-deploy-pipeline-run
  namespace: ${namespace}
spec:
  pipelineRef:
    name: nodejs-express-build-push-deploy-pipeline
  resources:
  - name: git-source
    resourceRef:
      name: ${PRJ_NAME}-git-source
  - name: docker-image
    resourceRef:
      name: ${PRJ_NAME}-docker-image
  serviceAccount: kabanero-operator
  timeout: 60m
EOF

oc get pipelinerun -n kabanero