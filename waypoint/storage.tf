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
    storage_class_name               = "efs-sc"

    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = "${data.terraform_remote_state.eks.outputs.efs_file_system_id}::${data.terraform_remote_state.eks.outputs.efs_access_point_server_id[count.index]}"
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
    storage_class_name               = "efs-sc"

    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = "${data.terraform_remote_state.eks.outputs.efs_file_system_id}::${data.terraform_remote_state.eks.outputs.efs_access_point_runner_id[count.index]}"
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

    storage_class_name = "efs-sc"
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

    storage_class_name = "efs-sc"
  }
}