project = "test-project"

app "api" {
  build {
    use "docker-pull" {
      image = "nicholasjackson/fake-service"
      tag   = "v0.23.1"
    }
  }

  deploy {
    use "kubernetes-apply" {
      path        = templatedir("${path.app}/config")
      prune_label = "app=api"
    }
  }
}