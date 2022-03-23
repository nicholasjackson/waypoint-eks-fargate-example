resource "aws_iam_role" "odr_runner" {
  name = "waypoint-odr-runner"

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
          "${module.eks.oidc_provider}:sub": "system:serviceaccount:default:waypoint-runner-odr"
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

resource "aws_iam_policy_attachment" "odr_runner_exec" {
  name       = "waypoint-odr-runner-exec"
  roles      = [aws_iam_role.odr_runner.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

resource "aws_iam_policy_attachment" "odr_runner_cni" {
  name       = "waypoint-odr-runner-cni"
  roles      = [aws_iam_role.odr_runner.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_policy_attachment" "odr_runner_ecr" {
  name       = "waypoint-odr-runner-ecr"
  roles      = [aws_iam_role.odr_runner.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "helm_release" "waypoint" {
  depends_on = ["helm_release.albingress"]
  name       = "waypoint"

  repository = "https://helm.releases.hashicorp.com"
  chart      = "waypoint"
  version    = "v0.1.6"
  timeout    = 500

  values = [
    "${file("values.yaml")}"
  ]

  set {
    name  = "runner.odr.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.odr_runner.arn
  }
}