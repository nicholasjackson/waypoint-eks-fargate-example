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

output "efs_access_point_id" {
  description = "EFS filesystem for Waypoint"
  value       = [aws_efs_access_point.waypoint_server.*.id]
}

output "efs_file_system_id" {
  description = "EFS filesystem for Waypoint"
  value       = aws_efs_file_system.waypoint.id
}