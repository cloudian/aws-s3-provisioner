#!/bin/sh -e

file="$(dirname "$0")/check-setup.yaml"

kubectl apply -f $file
sleep 5
kubectl logs check-setup | grep BUCKET_
kubectl delete -f $file
