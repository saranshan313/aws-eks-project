#EKS Cluster
resource "aws_eks_cluster" "eks_apps" {
  version  = local.settings.eks_clsuter.cluster_version
  name     = "eks-${local.settings.env}-${local.settings.region}-cluster-01"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      for k, v in data.terraform_remote_state.vpc.outputs.network_application_subnets : v
    ]
    endpoint_private_access = local.settings.eks_cluster.vpc_config.private_access
    endpoint_public_access  = local.settings.eks_cluster.vpc_config.public_access
  }
  enabled_cluster_log_types = local.settings.eks_cluster.log_types

  kubernetes_network_config {
    service_ipv4_cidr = local.settings.eks_cluster.network_config.service_ip_cidr
    ip_family         = local.settings.eks_cluster.network_config.ip_family
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController,
  ]
  tags = {
    Name = "eks-${local.settings.env}-${local.settings.region}-cluster-01"
  }
}

#EKS Add ons
resource "aws_eks_addon" "eks_apps" {
  for_each                    = local.settings.eks_cluster.add_on
  cluster_name                = aws_eks_cluster.eks_apps.name
  addon_name                  = each.key
  resolve_conflicts_on_create = each.value["resolve_conflict"]
  addon_version               = each.value["version"]
  depends_on = [
    aws_eks_node_group.demo_cluster
  ]
}

#EKS Node Groups
resource "aws_eks_node_group" "eks_apps" {
  for_each        = local.settings.eks_cluster.node_groups
  cluster_name    = aws_eks_cluster.eks_apps.name
  node_group_name = "$nodegrp-${local.settings.env}-${local.settings.region}-${each.value["name"]}-01"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids = [
    for k, v in data.terraform_remote_state.vpc.outputs.network_application_subnets : v
  ]

  scaling_config {
    desired_size = each.scaling_config.value["desire_count"]
    max_size     = each.scaling_config.value["max_size"]
    min_size     = each.scaling_config.value["min_size"]
  }

  update_config {
    max_unavailable = each.update_config.value["max_unavailable"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
  ]
  tags = {
    Name = "$nodegrp-${local.settings.env}-${local.settings.region}-${each.value["name"]}-01"
  }
}
