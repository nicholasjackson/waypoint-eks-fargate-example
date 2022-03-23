output "cluster_name" {
  value = local.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_primary_security_group_id
}

output "region" {
  description = "AWS region."
  value       = var.region
}

#output "efs_access_point_server_id" {
#  description = "EFS filesystem for Waypoint Server"
#  value       = aws_efs_access_point.waypoint_server.*.id
#}
#
#output "efs_access_point_runner_id" {
#  description = "EFS filesystem for Waypoint Runner"
#  value       = aws_efs_access_point.waypoint_runner.*.id
#}
#
#output "efs_file_system_id" {
#  description = "EFS filesystem for Waypoint"
#  value       = aws_efs_file_system.waypoint.id
#}

output "kubernetes_endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}

output "kubernetes_certificate" {
  value = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

output "kubernetes_token" {
  sensitive = true
  value     = data.aws_eks_cluster_auth.cluster.token
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  value = module.eks.oidc_provider
}