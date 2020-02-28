# Hyperstore S3 operator
This document describes how to deploy or run Hyperstore S3 k8s operator on k8s Cluster.
## Getting Started
### Prerequisites
This project requires a k8s environment and Minikube needs to be installed before we start.<br>
Install Minikube
```
 $ brew install minikube
 $ minikube start --kubernetes-version v1.17.0
```
### Installing
1. Download objectbucket_v1alpha1_objectbucket_crd.yaml and objectbucket_v1alpha1_objectbucketclaim_crd.yaml from https://github.com/kube-object-storage/lib-bucket-provisioner/tree/master/deploy/crds, then create the ObjectBucket and ObjectBucketClaim
```
 $ kubectl create -f objectbucket_v1alpha1_objectbucket_crd.yaml
 $ kubectl create -f objectbucket_v1alpha1_objectbucketclaim_crd.yaml
```

2. Deploy the latest Hyperstore S3 Provisioner and create a ClusterRoleBinding.<br>
Create namespace named s3-provisioner
```
apiVersion: v1
kind: Namespace
metadata:
  name: s3-provisioner
```
ClusterRoleBinding
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aws-s3-provisioner-deployment
  namespace: s3-provisioner
  labels:
    app: aws-s3-provisioner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aws-s3-provisioner
  template:
    metadata:
      labels:
        app: aws-s3-provisioner
    spec:
      containers:
      - name: aws-s3-provisioner
        image: quay.io/screeley44/aws-s3-provisioner:v1.0.0
        imagePullPolicy: Always
      restartPolicy: Always
```
Then use the following command <br>
```
 $ kubectl create -f s3-namespaces.yaml
 $ kubectl create -f aws-s3-provisioner-deployment.yaml
```

3. Create a ClusterRoleBinding for the default serviceaccount that will run your provisioner.
``` 
  kubectl create clusterrolebinding <rolename> --clusterrole=cluster-admin --user=system:serviceaccount:<namespace>:default
  i.e.
  # kubectl create clusterrolebinding cluster-admin-aws --clusterrole=cluster-admin --user=system:serviceaccount:s3-provisioner:default
```

### Administrator Creates Secret
This secret will contain the elevated/admin privileges needed by the provisioner to properly access and create S3 Buckets and IAM users and policies. The Hyperstore Access ID and Hyperstore Secret Key will be needed for this.<br>
1. Create the Kubernetes Secret for the Provisioner's Owner Access.
``` 
apiVersion: v1
kind: Secret
metadata:
  name: s3-bucket-owner [1]
  namespace: s3-provisioner [2]
type: Opaque
data:
  AWS_ACCESS_KEY_ID: *base64 encoded value* [3]
  AWS_SECRET_ACCESS_KEY: *base64 encoded value* [4]
``` 
[1] Name of the secret, this will be referenced in StorageClass.<br>
[2] Namespace where the Secret will exist.<br>
[3] Your AWS_ACCESS_KEY_ID base64 encoded. Encode your AWS_ACCESS_KEY_ID of your AWS account from https://www.base64encode.org/ <br>
[4] Your AWS_SECRET_ACCESS_KEY base64 encoded. Encode your AWS_SECRET_ACCESS_KEY of your AWS account from https://www.base64encode.org/ <br>
Then create secret/s3-bucket-owner
``` 
# kubectl create -f creds.yaml
secret/s3-bucket-owner created
``` 
2. Administrator Creates StorageClass
The StorageClass defines the name of the provisioner and holds other properties that are needed to provision a new bucket, including the Owner Secret and Namespace, and the Hyperstore Region.<br>
Create the Kubernetes StorageClass for the Provisioner.
``` 
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: s3-buckets [1]
provisioner: aws-s3.io/bucket [2]
parameters:
  region: us-west-1 [3]
  secretName: s3-bucket-owner [4]
  secretNamespace: s3-provisioner [5]
reclaimPolicy: Delete [6]
``` 
[1] Name of the StorageClass, this will be referenced in the User ObjectBucketClaim. <br>
[2] Provisioner name <br>
[3] Hyperstore Region that the StorageClass will serve <br>
[4] Name of the bucket owner Secret created above <br>
[5] Namespace where the Secret will exist <br>
[6] reclaimPolicy (Delete or Retain) indicates if the bucket can be deleted when the OBC is deleted.<br>
NOTE: the absence of the bucketName Parameter key in the storage class indicates this is a new bucket and its name is based on the bucket name fields in the OBC.
``` 
# kubectl create -f storageclass-greenfield.yaml
storageclass.storage.k8s.io/s3-buckets created
``` 
3. User Creates ObjectBucketClaim
An ObjectBucketClaim follows the same concept as a PVC, in that it is a request for Object Storage, the user doesn't need to concern him/herself with the underlying storage, just that they need access to it. The user will work with the cluster/storage administrator to get the proper StorageClass needed and will then request access via the OBC.
Create the ObjectBucketClaim.
``` 
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: myobc [1]
  namespace: s3-provisioner [2]
spec:
  generateBucketName: mybucket-prefix- [3]
  bucketName: my-awesome-bucket [4]
  storageClassName: s3-buckets [5]
  additionalConfig:
    additionalProperties: test[6]
 ``` 
[1] Name of the OBC <br>
[2] Namespace of the OBC <br>
[3] Name prepended to a random string used to generate a bucket name. It is ignored if bucketName is defined <br>
[4] Name of new bucket which must be unique across all Hyperstore regions, otherwise an error occurs when creating the bucket. If present, this name overrides generateName <br>
[5] StorageClass name <br>
[6] set any object name here <br>
```diff
- NOTE: Only remain either generateBucketName or bucketName in this document, otherwise error will occur.<br>
- BucketName must be globally unique.
```
Then use the following command
```
# kubectl create -f obc-brownfield.yaml
objectbucketclaim.objectbucket.io/myobc created
```

### Results and Recap
Let's pause for a moment and digest what just happened. After creating the OBC, and assuming the S3 provisioner is running, we now have the following Kubernetes resources: . a global ObjectBucket (OB) which contains: bucket endpoint info (including region and bucket name), a reference to the OBC, and a reference to the storage class. Unique to S3, the OB also contains the bucket Amazon Resource Name (ARN).Note: there is always a 1:1 relationship between an OBC and an OB. . a ConfigMap in the same namespace as the OBC, which contains the same endpoint data found in the OB. . a Secret in the same namespace as the OBC, which contains the Hyperstore key-pairs needed to access the bucket.
And of course, we have a new Hyperstore S3 Bucket which you should be able to see via the Hyperstore Console.
ObjectBucket<br>
The installation status can be confirmed in two ways:
1. Login in your Hyperstore account to confirm whether new bucket has been created.
2. using command line to check thether new bucket has been created.
```
 $ cd .aws/
 $ vi config
 (change AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to your AWS account)
 $ aws s3 ls
```
### Uninstalling
If you have installed minikube using the direct download method, follow the below steps to uninstall minikube completely from your system <br>
- In the shell, type in 
```
$ minikube delete 
```
to delete the minikube cluster. <br>
- Uninstall the minikube package using 
```
$ brew uninstall minikube 
```
- Remove the directory containing the minikube configuration 
```
$ rm -rf ~/.minikube
```
### Useful commands
Check log status
```
$ kubectl log aws-s3-provisioner-deployment-94987d57-dsjxc -n s3-provisioner
```
Check deployment status
```
$ kubectl get deployment -n s3-provisioner
```
Check pod status
```
$ kubectl get pod -n s3-provisioner
```
