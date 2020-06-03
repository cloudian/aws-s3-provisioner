module github.com/yard-turkey/aws-s3-provisioner

go 1.14

require (
	github.com/aws/aws-sdk-go v1.31.5
	github.com/golang/glog v0.0.0-20160126235308-23def4e6c14b
	github.com/imdario/mergo v0.3.7 // indirect
	github.com/kube-object-storage/lib-bucket-provisioner v0.0.0-20200219192502-02cba53742ae
	//k8s.io/api v0.0.0-20190313115550-3c12c96769cc
	k8s.io/api v0.0.0-20191016110408-35e52d86657a
	k8s.io/apimachinery v0.0.0-20191004115801-a2eda9f80ab8
	k8s.io/client-go v0.0.0-20191016111102-bec269661e48
)
