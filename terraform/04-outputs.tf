output "eks_lb_dns_name" {
  description = "DNS Name of the EKS Load Balancer"
  value       = try(aws_lb.eks_alb.dns_name, null)
}

output "eks_endpoint" {
  description = "Endpoint of the EKS Cluster"
  value       = try(aws_eks_cluster.eks_apps.endpoint, null)
}

output "eks_ca" {
  description = "CA of the EKS Cluster"
  value       = try(aws_eks_cluster.eks_apps.certificate_authority[0].data, null)
}

output "eks_oidc_issuer" {
  description = "Issuer URL of the OIDC for EKS Cluster"
  value       = try(aws_eks_cluster.eks_apps.identity[0].oidc[0].issuer, null)
}

output "eks_oidc_arn" {
  description = "ARN of OIDC provider for EKS Cluster"
  value       = try(aws_iam_openid_connect_provider.oidc_provider.arn, null)
}

output "eks_cluster_name" {
  description = "Name of the EKS Cluster"
  value       = try(aws_eks_cluster.eks_apps.id, null)
}

output "eks_nodegrp_sgs" {
  description = "Id of the EKS Node Group Security Groups"
  value       = try([aws_security_group.eks_nodegrp_sg.id, aws_security_group.eks_cluster_sg.id], null)
}

output "eks_node_instance_profile" {
  description = "Instance Profile of the EKS Nodes"
  value       = try(aws_iam_instance_profile.node_group_role.arn, null)
}
