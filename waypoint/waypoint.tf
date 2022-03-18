resource "helm_release" "waypoint" {
  depends_on = [kubernetes_persistent_volume_claim.waypoint_server, kubernetes_persistent_volume_claim.waypoint_runner]
  name       = "waypoint"

  repository = "https://helm.releases.hashicorp.com"
  chart      = "waypoint"
  version    = "v0.1.6"
  timeout    = 500

  values = [
    "${file("values.yaml")}"
  ]
}