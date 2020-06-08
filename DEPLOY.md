## Cloudian S3 Kubernetes Provisioner

This guide shows you how to deploy the Cloudian S3 Provisioner for Kubernetes to allow you to use Object Bucket Claim, so your deployments have easy access to HyperStore buckets.

It assumes a good working knowledge of Kubernetes and that you have `kubectl` on your path with permissions to run it.

## Create the Object Bucket and Object Bucket Claim Custom Resource Definitions.

Firstly, we need to create the generic Object Bucket and Object Bucket provisioner resources.  This only needs to be done once.

Simply run
```bash
kubectl apply -f https://raw.githubusercontent.com/kube-object-storage/lib-bucket-provisioner/master/deploy/crds/objectbucket_v1alpha1_objectbucket_crd.yaml
kubectl apply -f https://raw.githubusercontent.com/kube-object-storage/lib-bucket-provisioner/master/deploy/crds/objectbucket_v1alpha1_objectbucketclaim_crd.yaml
```

## Deploy the S3 provisioner

Next we need to deploy the Cloudian provisioner.  This only needs to be done once per Kubernetes cluster.

Simply run
```yaml
kubectl apply -f https://raw.githubusercontent.com/cloudian/aws-s3-provisioner/hyperstore/examples/cloudian-s3-provisioner.yaml
```
This deploys a provisioner in the `s3-provisioner` namespace.

### Create owner secret

We need to give the Kubernetes cluster the ability to connect to HyperStore.  You need credentials from a user who has sufficient rights to create/delete/get buckets and IAM users.  Again, only one of these is needed per Kubernetes cluster.

Create 'owner-secret.yaml':
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: s3-bucket-owner
  namespace: s3-provisioner
type: Opaque
data:
  AWS_ACCESS_KEY_ID: base64_encoded_key
  AWS_SECRET_ACCESS_KEY: base64_encoded_secret
```
Ensure that your base64 encoded secret does not include the newline, using for example
```
echo -n <raw key> | base64
```
to create it.

Apply it with:
```bash
kubectl apply -f owner-secret.yaml
```

As an alternative to using a YAML file for the owner secret, create these from the command line
```bash
kubectl create secret -n s3-provisioner generic s3-bucket-owner --from-literal=AWS_ACCESS_KEY_ID=<access key> --from-literal=AWS_SECRET_ACCESS_KEY=<secret key> 
```

### Create storage class

You may need multiple storage classes.  You can either create "greenfield" (each new deployment gets access to a newly created, empty bucket) or "brownfield" (each deployment gets access to a pre-created bucket) type classes.

Create `storage-class.yaml`:
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: <tag for this class, e.g. hyperstore-buckets>
provisioner: aws-s3.io/bucket
parameters:
  region: <region e.g. reg-1>
  secretName: s3-bucket-owner
  secretNamespace: s3-provisioner
  bucketName: <existing bucket name, e.g. photos, or delete> - brownfield only
  s3Endpoint: <API server URL, e.g. http://s3-reg-1.landemo1.cloudian.eu>
  iamEndpoint: <IAM API server URL, e.g. http://iam.landemo1.cloudian.eu:16080>
  storagePolicyId: <Storage Policy ID - or omit line to use default storage policy> - greenfield only
  iamPolicy: <IAM policy document (JSON string) for users of this bucket - omit to use default IAM policy (read+write bucket)>
reclaimPolicy: Delete
```

This file needs some customisation, depending on your setup.

1. Change metdata.name to a unique tag for this storage class.
1. Change region, s3Endpoint and iamEndpoint to match your HyperStore setup
1. For greenfield: delete bucketName and optionally set the storage policy to use for new buckets. Omit the storagePolicyId line to use the default policy. To find the policy ID, navigate to the Cluster->Storage Policies page on the CMC, select View/Edit for the policy, and copy the ID field (above the Policy Name field)
1. For brownfield: specify an already created bucket name and delete reclaimPolicy and storagePolicyId
1. Optionally specify an iam policy document to override default read+write access to the bucket. You do not need to specify `Resource` fields - they will be set to only allow access to the claimed bucket. For example, to grant read-only access to the bucket:
```yaml
  iamPolicy: |
    {
      "Version": "2012-10-17",
      "Statement": [{
              "Sid": "AllowAll",
              "Effect": "Allow",
              "Action": ["s3:HeadObject", "s3:ListBucket", "s3:GetObject"]
      }]
    }
```

Apply this with:
```bash
kubectl apply -f storage-class.yaml
```

### Checking your setup

Create a `test.yaml` file that creates bucket claim and pod that binds environment variables to the config map and secret the provisioner generates:
```yaml
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: test-setup-check
spec:
  generateBucketName: test-setup-check
  storageClassName: <object storage class you want to check, e.g. hyperstore-buckets>
---
apiVersion: v1
kind: Pod
metadata:
  name: test-setup-check
spec:
  containers:
  - name: test-setup-check
    image: k8s.gcr.io/busybox
    command: [ "/bin/sh", "-c", "env" ]
    envFrom:
    - configMapRef:
        name: test-setup-check
    - secretRef:
        name: test-setup-check
  restartPolicy: Never
```
Deploy the `test.yaml`, wait until the test pod exists, then look at the logs and check the environment variables. Use the HyperStore CMC to verify the bucket has been created and an IAM user created that only has access rights to the bucket.
```
kubectl apply -f test.yaml
kubectl get pods -w test-setup-check
# Wait until pod is status completed, then hit ctrl-c
kubectl logs test-setup-check | grep BUCKET_
```
You should see the following environment variables set
```bash
BUCKET_HOST=s3-reg-1.landemo1.cloudian.eu
BUCKET_PORT=80
BUCKET_NAME=check-setup-ccf09b7c-ce06-431c-bc7d-9ddd5af8d192
BUCKET_SUBREGION=
BUCKET_REGION=reg-1
```
and the bucket and similarly looking IAM user created.  You'll also see the AWS credentials in the log too.  These details can be used to access HyperStore for that bucket only.

Delete this deployment, and use the CMC to check the test bucket and IAM user have been deleted:
```
kubectl delete -f test.yaml
```
If you look in CMC, you'll see the bucket and IAM user are gone.
