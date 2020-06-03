#!/bin/bash

keep=false
if [ "$1" == "--keep" ]; then
  keep=true
  shift
fi

field=${1:-green}field
if [ "$field" != "greenfield" ] && [ "$field" != "brownfield" ]; then
  echo "usage: down-prod.sh [green|brown]"
  exit 1
fi

examples=$(dirname "$0")/../examples

kubectl delete -f "$examples/$field/photo.yaml"
kubectl delete -f "$examples/$field/storageclass.yaml"

if $keep; then
  exit 0
fi

kubectl delete -f "$examples/owner-secret.yaml"
kubectl delete -f "$examples/cloudian-s3-provisioner.yaml"
kubectl delete -f "https://raw.githubusercontent.com/kube-object-storage/lib-bucket-provisioner/master/deploy/crds/objectbucket_v1alpha1_objectbucket_crd.yaml"
kubectl delete -f "https://raw.githubusercontent.com/kube-object-storage/lib-bucket-provisioner/master/deploy/crds/objectbucket_v1alpha1_objectbucketclaim_crd.yaml"
