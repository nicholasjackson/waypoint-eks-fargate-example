project = "testing1"

app "api" {
  build {
    use "docker" {
      buildkit           = false
      disable_entrypoint = false
    }

    registry {
      use "aws-ecr" {
        repository = "hashicorp-dev-hello-world"
        region     = "eu-west-1"
        tag        = "v2"
      }
    }
  }

  deploy {
    use "kubernetes" {
      probe_path = "/"
      namespace  = "waypoint-apps"
    }
  }
}
