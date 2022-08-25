#!/bin/bash

# Generate argocd manifests for current version for installer chart
MYDIR=$(dirname $0)
ARGOCD_KUSTOMIZE_DIR=$MYDIR/../../../basic/apps/argo-cd

kustomize build $ARGOCD_KUSTOMIZE_DIR > argocd_manifests.yaml