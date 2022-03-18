project = "testing"

app "api" {
  build {
    use "docker" {}
  }

  deploy {
    use "kubernetes-apply" {
      path        = templatedir("${path.app}/config")
      prune_label = "app=api"
    }
  }
}
