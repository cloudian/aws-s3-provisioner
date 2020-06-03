#!/bin/bash -e

field=${1:-green}field
if [ "$field" != "greenfield" ] && [ "$field" != "brownfield" ]; then
  echo "usage: up-prod.sh [green|brown]"
  exit 1
fi

examples=$(dirname "$0")/../examples

kubectl apply -f "https://raw.githubusercontent.com/kube-object-storage/lib-bucket-provisioner/master/deploy/crds/objectbucket_v1alpha1_objectbucket_crd.yaml"
kubectl apply -f "https://raw.githubusercontent.com/kube-object-storage/lib-bucket-provisioner/master/deploy/crds/objectbucket_v1alpha1_objectbucketclaim_crd.yaml"
kubectl apply -f "$examples/cloudian-s3-provisioner.yaml"
kubectl apply -f "$examples/owner-secret.yaml"
kubectl apply -f "$examples/$field/storageclass.yaml"
kubectl apply -f "$examples/$field/photo.yaml"
kubectl get pods -w
