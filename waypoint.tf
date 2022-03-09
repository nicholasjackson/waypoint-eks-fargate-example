resource "helm_release" "waypoint" {
  depends_on = [module.eks, module.vpc, kubernetes_persistent_volume_claim.waypoint_server]
  name       = "waypoint"

  repository = "https://helm.releases.hashicorp.com"
  chart      = "waypoint"
  version    = "v0.1.6"
  timeout    = 500

  values = [
    "${file("values.yaml")}"
  ]
}