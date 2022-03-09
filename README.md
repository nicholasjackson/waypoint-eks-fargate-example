# AWS EKS Fargate With Consul Service Mesh Example

### Creates:

* EKS Cluster with Fargate Profile
* Security Groups and Subnets
* EFS Volumes and Access Points for Waypoint
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

Create a kubeconfig using the AWS CLI

```
aws eks update-kubeconfig --region $(terraform output --raw region) --name $(terraform output --raw cluster_name)
```

## Install Waypoint

```
waypoint install -platform=kubernetes -accept-tos
```

## Destroying the demo

Running resources cost money so do not forget to tear down your cluster, you can run the `terraform destroy` command to remove 
all the resources you have created.

```shell
terraform destroy
```
