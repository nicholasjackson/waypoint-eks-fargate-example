# ECR repo for the example app
module "ecr" {
  source               = "cloudposse/ecr/aws"
  namespace            = "hashicorp"
  stage                = "dev"
  name                 = "hello-world"
  image_tag_mutability = "MUTABLE"
  //principals_full_access = ["arn:aws:iam::938765688536:role/waypoint-runner", "arn:aws:iam::938765688536:role/waypoint-server-execution-role"]

  tags = {
    Environment = "Development"
    Owner       = "Nic Jackson"
    Project     = "Waypoint ECS Test"
  }
}