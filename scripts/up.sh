#!/bin/bash -e

cd "$(dirname "$0")/.."

runprovision=true
if [ "$1" == "--nop" ]; then
  runprovision=false
  shift
fi

FIELD=${1:-green}field
if [ "$FIELD" != "greenfield" ] && [ "$FIELD" != "brownfield" ]; then
  echo "usage: up.sh [--nop] [green|brown]"
  exit 1
fi
 
# Prepare to run our provisiner
kubectl apply -f https://raw.githubusercontent.com/kube-object-storage/lib-bucket-provisioner/master/deploy/crds/objectbucket_v1alpha1_objectbucket_crd.yaml
kubectl apply -f https://raw.githubusercontent.com/kube-object-storage/lib-bucket-provisioner/master/deploy/crds/objectbucket_v1alpha1_objectbucketclaim_crd.yaml
kubectl apply -f examples/cloudian-s3-provisioner-dev.yaml
kubectl apply -f examples/owner-secret.yaml
kubectl apply -f "examples/$FIELD/storageclass.yaml"

# Start provisioner
if $runprovision; then
    SERVER=$(grep server ~/.kube/config | awk '{ print $2 }')
    go run ./cmd -master "$SERVER" -kubeconfig ~/.kube/config -alsologtostderr -v=2 &
fi

# Install the app and watch its creation
kubectl apply -f "examples/$FIELD/photo.yaml"
kubectl get pods -w
