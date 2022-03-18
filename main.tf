terraform {
  required_version = ">= 1.0.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.0.3"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.0.3"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.28.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 2.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 1.2"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 2.1"
    }

    template = {
      source  = "hashicorp/template"
      version = "~> 2.1"
    }
  }
}

provider "aws" {
  region = var.region
}


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

locals {
  cluster_name     = "test-eks-${random_string.suffix.result}"
  image_repository = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/amazon/aws-load-balancer-controller"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.12.0"

  name = var.vpc_name

  cidr = "172.16.0.0/16"
  azs  = data.aws_availability_zones.available.names

  private_subnets = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets  = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}