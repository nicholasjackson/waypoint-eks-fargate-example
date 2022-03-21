# AWS EKS Fargate With Consul Service Mesh Example

### Creates:

* EKS Cluster with Fargate Profile
* Security Groups and Subnets
* EFS Volumes and Access Points for Waypoint
* 
* Kubernetes Volumes and Claims using EFS for Waypoint

## Install Terraform 1.13

https://releases.hashicorp.com

You will also need to set your AWS credentials for Terraform

https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication

## KubeConfig

First install the AWS CLI

```shell
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm awscliv2.zip
```

## Configure Waypoint

Get the address of the Waypoint server from Kubernetes

```shell
export WAYPOINT_HOST=$(kubectl get svc waypoint-ui -o=jsonpath="{.status.loadBalancer.ingress[0].hostname}")
export WAYPOINT_TOKEN=$(kubectl get secrets waypoint-server-token -o=jsonpath="{.data.token}" | base64 -d)
waypoint context create -server-addr="${WAYPOINT_HOST}:9701" -server-auth-token=${WAYPOINT_TOKEN} -server-tls-skip-verify=true -set-default=true -server-require-auth=true eks
```

## Open the Waypoint UI

```shell
waypoint ui -authenticate
```

## Configure the application

## Destroying the demo

Running resources cost money so do not forget to tear down your cluster, you can run the `terraform destroy` command to remove 
all the resources you have created.

```shell
terraform destroy
```
