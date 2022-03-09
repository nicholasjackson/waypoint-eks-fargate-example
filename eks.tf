module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.8.1"

  cluster_name    = local.cluster_name
  cluster_version = "1.21"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  tags = {
    Environment = "test"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # You require a node group to schedule coredns which is critical for running correctly internal DNS.
  # If you want to use only fargate you must follow docs `(Optional) Update CoreDNS`
  # available under https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html
  eks_managed_node_groups = {
    example = {
      desired_size = 1

      instance_types = ["t3.small"]
      labels = {
        Example    = "managed_node_groups"
        GithubRepo = "terraform-aws-eks"
        GithubOrg  = "terraform-aws-modules"
      }
      tags = {
        ExtraTag = "example"
      }
    }
  }

  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "default"
        }
      ]

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    }
  }
}

resource "kubernetes_storage_class" "efs" {
  depends_on = [module.eks]

  metadata {
    name = "efs-sc"
  }

  storage_provisioner = "efs.csi.aws.com"
}

resource "kubernetes_persistent_volume" "efs_pv_server" {
  count = 1

  metadata {
    name = "efs-pv-server-${count.index}"
  }

  spec {
    capacity = {
      storage = "10Gi"
    }
    volume_mode                      = "Filesystem"
    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Delete"
    storage_class_name               = kubernetes_storage_class.efs.metadata.0.name

    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = "${aws_efs_file_system.waypoint.id}::${aws_efs_access_point.waypoint_server[count.index].id}"
      }
    }
  }
}

resource "kubernetes_persistent_volume" "efs_pv_runner" {
  count = 1

  metadata {
    name = "efs-pv-runner-${count.index}"
  }

  spec {
    capacity = {
      storage = "10Gi"
    }
    volume_mode                      = "Filesystem"
    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Delete"
    storage_class_name               = kubernetes_storage_class.efs.metadata.0.name

    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = "${aws_efs_file_system.waypoint.id}::${aws_efs_access_point.waypoint_runner[count.index].id}"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "waypoint_server" {
  count      = 1
  depends_on = [kubernetes_persistent_volume.efs_pv_server]

  metadata {
    name = "data-default-waypoint-server-${count.index}"
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }

    storage_class_name = kubernetes_storage_class.efs.metadata.0.name
  }
}

resource "kubernetes_persistent_volume_claim" "waypoint_runner" {
  count      = 1
  depends_on = [kubernetes_persistent_volume.efs_pv_runner]

  metadata {
    name = "data-default-waypoint-runner-${count.index}"
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }

    storage_class_name = kubernetes_storage_class.efs.metadata.0.name
  }
}