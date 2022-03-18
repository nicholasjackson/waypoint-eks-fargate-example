project = "testing"

app "api" {
  build {
    use "docker" {
      buildkit           = false
      disable_entrypoint = false
    }
  }

  deploy {
    use "kubernetes-apply" {
      path        = templatedir("${path.app}/config")
      prune_label = "app=api"
    }
  }
}
