module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.8.1"

  cluster_name    = local.cluster_name
  cluster_version = "1.21"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets
  enable_irsa = true

  tags = {
    Environment = "test"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  cluster_addons = {
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }

    kube-proxy = {}
  }

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  fargate_profiles = {
    default = {
      iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"]
      name                         = "default"
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

    system = {
      name = "system"
      selectors = [
        {
          namespace = "kube-system"
        }
      ]

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    }
  }
}

# Install and modify coredns
resource "null_resource" "add_core_dns" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<EOF
      aws eks update-kubeconfig \
        --region ${var.region} \
        --name ${local.cluster_name};

      aws eks create-addon \
        --region ${var.region} \
        --cluster-name ${local.cluster_name} \
        --addon-name coredns \
        --resolve-conflicts OVERWRITE;

      kubectl patch deployment coredns \
        --namespace kube-system \
        --type=json \
        -p='[{"op": "remove", "path": "/spec/template/metadata/annotations", "value": "eks.amazonaws.com/compute-type"}]';
    EOF
  }
}

resource "aws_iam_policy" "albingress" {
  name        = "albingress"
  description = format("Allow alb-ingress-controller to manage AWS resources")
  path        = "/"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "iam:CreateServiceLinkedRole"
          ],
          "Resource": "*",
          "Condition": {
              "StringEquals": {
                  "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
              }
          }
      },
      {
          "Effect": "Allow",
          "Action": [
              "ec2:DescribeAccountAttributes",
              "ec2:DescribeAddresses",
              "ec2:DescribeAvailabilityZones",
              "ec2:DescribeInternetGateways",
              "ec2:DescribeVpcs",
              "ec2:DescribeVpcPeeringConnections",
              "ec2:DescribeSubnets",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeInstances",
              "ec2:DescribeNetworkInterfaces",
              "ec2:DescribeTags",
              "ec2:GetCoipPoolUsage",
              "ec2:DescribeCoipPools",
              "elasticloadbalancing:DescribeLoadBalancers",
              "elasticloadbalancing:DescribeLoadBalancerAttributes",
              "elasticloadbalancing:DescribeListeners",
              "elasticloadbalancing:DescribeListenerCertificates",
              "elasticloadbalancing:DescribeSSLPolicies",
              "elasticloadbalancing:DescribeRules",
              "elasticloadbalancing:DescribeTargetGroups",
              "elasticloadbalancing:DescribeTargetGroupAttributes",
              "elasticloadbalancing:DescribeTargetHealth",
              "elasticloadbalancing:DescribeTags"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "cognito-idp:DescribeUserPoolClient",
              "acm:ListCertificates",
              "acm:DescribeCertificate",
              "iam:ListServerCertificates",
              "iam:GetServerCertificate",
              "waf-regional:GetWebACL",
              "waf-regional:GetWebACLForResource",
              "waf-regional:AssociateWebACL",
              "waf-regional:DisassociateWebACL",
              "wafv2:GetWebACL",
              "wafv2:GetWebACLForResource",
              "wafv2:AssociateWebACL",
              "wafv2:DisassociateWebACL",
              "shield:GetSubscriptionState",
              "shield:DescribeProtection",
              "shield:CreateProtection",
              "shield:DeleteProtection"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "ec2:AuthorizeSecurityGroupIngress",
              "ec2:RevokeSecurityGroupIngress"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "ec2:CreateSecurityGroup"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "ec2:CreateTags"
          ],
          "Resource": "arn:aws:ec2:*:*:security-group/*",
          "Condition": {
              "StringEquals": {
                  "ec2:CreateAction": "CreateSecurityGroup"
              },
              "Null": {
                  "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
              }
          }
      },
      {
          "Effect": "Allow",
          "Action": [
              "ec2:CreateTags",
              "ec2:DeleteTags"
          ],
          "Resource": "arn:aws:ec2:*:*:security-group/*",
          "Condition": {
              "Null": {
                  "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                  "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
              }
          }
      },
      {
          "Effect": "Allow",
          "Action": [
              "ec2:AuthorizeSecurityGroupIngress",
              "ec2:RevokeSecurityGroupIngress",
              "ec2:DeleteSecurityGroup"
          ],
          "Resource": "*",
          "Condition": {
              "Null": {
                  "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
              }
          }
      },
      {
          "Effect": "Allow",
          "Action": [
              "elasticloadbalancing:CreateLoadBalancer",
              "elasticloadbalancing:CreateTargetGroup"
          ],
          "Resource": "*",
          "Condition": {
              "Null": {
                  "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
              }
          }
      },
      {
          "Effect": "Allow",
          "Action": [
              "elasticloadbalancing:CreateListener",
              "elasticloadbalancing:DeleteListener",
              "elasticloadbalancing:CreateRule",
              "elasticloadbalancing:DeleteRule"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "elasticloadbalancing:AddTags",
              "elasticloadbalancing:RemoveTags"
          ],
          "Resource": [
              "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
              "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
              "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
          ],
          "Condition": {
              "Null": {
                  "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                  "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
              }
          }
      },
      {
          "Effect": "Allow",
          "Action": [
              "elasticloadbalancing:AddTags",
              "elasticloadbalancing:RemoveTags"
          ],
          "Resource": [
              "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
              "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
              "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
              "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
          ]
      },
      {
          "Effect": "Allow",
          "Action": [
              "elasticloadbalancing:ModifyLoadBalancerAttributes",
              "elasticloadbalancing:SetIpAddressType",
              "elasticloadbalancing:SetSecurityGroups",
              "elasticloadbalancing:SetSubnets",
              "elasticloadbalancing:DeleteLoadBalancer",
              "elasticloadbalancing:ModifyTargetGroup",
              "elasticloadbalancing:ModifyTargetGroupAttributes",
              "elasticloadbalancing:DeleteTargetGroup"
          ],
          "Resource": "*",
          "Condition": {
              "Null": {
                  "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
              }
          }
      },
      {
          "Effect": "Allow",
          "Action": [
              "elasticloadbalancing:RegisterTargets",
              "elasticloadbalancing:DeregisterTargets"
          ],
          "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "elasticloadbalancing:SetWebAcl",
              "elasticloadbalancing:ModifyListener",
              "elasticloadbalancing:AddListenerCertificates",
              "elasticloadbalancing:RemoveListenerCertificates",
              "elasticloadbalancing:ModifyRule"
          ],
          "Resource": "*"
      }
  ]
}
EOF
}

resource "aws_iam_role" "albingress" {
  name = "albingress"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${module.eks.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${module.eks.oidc_provider}:aud": "sts.amazonaws.com",
          "${module.eks.oidc_provider}:sub": "system:serviceaccount:kube-system:${local.alb_service_account}"
        }
      }
    }
  ]
}
EOF

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_policy_attachment" "albingress" {
  name       = "albingress"
  roles      = [aws_iam_role.albingress.name]
  policy_arn = aws_iam_policy.albingress.arn
}

locals {
  alb_service_account = "aws-alb-ingress-controller"
}

resource "helm_release" "albingress" {
  name            = "aws-alb-ingress-controller"
  chart           = "aws-load-balancer-controller"
  repository      = "https://aws.github.io/eks-charts"
  namespace       = "kube-system"
  cleanup_on_fail = true

  dynamic "set" {
    for_each = {
      "autoDiscoverAwsRegion"                                     = false
      "autoDiscoverAwsVpcID"                                      = false
      "clusterName"                                               = local.cluster_name
      "serviceAccount.name"                                       = local.alb_service_account
      "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = aws_iam_role.albingress.arn
      "region"                                                    = var.region
      "vpcId"                                                     = module.vpc.vpc_id
      "replicaCount"                                              = 1
    }
    content {
      name  = set.key
      value = set.value
    }
  }
}