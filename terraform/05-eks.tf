#EKS Cluster
resource "aws_eks_cluster" "eks_apps" {
  version  = local.settings.eks_cluster.cluster_version
  name     = "eks-${local.settings.env}-${local.settings.region}-cluster-01"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      for k, v in data.terraform_remote_state.vpc.outputs.network_application_subnets : v
    ]
    endpoint_private_access = local.settings.eks_cluster.vpc_config.private_access
    endpoint_public_access  = local.settings.eks_cluster.vpc_config.public_access

    security_group_ids = [
      aws_security_group.eks_cluster_sg.id
    ]

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
  addon_name                  = each.value["name"]
  resolve_conflicts_on_create = each.value["resolve_conflict"]
  addon_version               = each.value["version"]
  depends_on = [
    aws_eks_node_group.eks_apps
  ]
}

#EKS Node Groups
resource "aws_eks_node_group" "eks_apps" {
  for_each        = local.settings.eks_cluster.node_groups
  cluster_name    = aws_eks_cluster.eks_apps.name
  node_group_name = "nodegrp-${local.settings.env}-${local.settings.eks_cluster.node_groups[each.key].name}-01"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids = [
    for k, v in data.terraform_remote_state.vpc.outputs.network_application_subnets : v
  ]

  scaling_config {
    desired_size = local.settings.eks_cluster.node_groups[each.key].scaling_config.desire_count
    max_size     = local.settings.eks_cluster.node_groups[each.key].scaling_config.max_size
    min_size     = local.settings.eks_cluster.node_groups[each.key].scaling_config.min_size
  }

  launch_template {
    name = format("lt-%s-%s-%s-01",
      local.settings.env,
      local.settings.region,
      local.settings.eks_cluster.node_groups[each.key].name
    )
    version = "$Default"
  }

  update_config {
    max_unavailable = local.settings.eks_cluster.node_groups[each.key].update_config.max_unavailable
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
    aws_vpc_endpoint.eks_cluster_vpce
  ]
  tags = {
    Name = "nodegrp-${local.settings.env}-${local.settings.region}-${local.settings.eks_cluster.node_groups[each.key].name}-01"
  }
}

#Launch templates for EKS node groups
resource "aws_launch_template" "eks_node_groups" {
  for_each = local.settings.eks_cluster.node_groups
  name = format("lt-%s-%s-%s-01",
    local.settings.env,
    local.settings.region,
    local.settings.eks_cluster.node_groups[each.key].name
  )
  instance_type = local.settings.eks_cluster.node_groups[each.key].instance_type
  vpc_security_group_ids = [
    aws_security_group.eks_nodegrp_sg.id,
    aws_security_group.eks_cluster_sg.id
  ]

  update_default_version = true

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = format("node-%s-%s-%s-01",
        local.settings.env,
        local.settings.region,
        local.settings.eks_cluster.node_groups[each.key].name
      )
    }
  }
}

#Security Group for EKS Cluster
resource "aws_security_group" "eks_cluster_sg" {
  name        = "secgrp-${local.settings.env}-${local.settings.region}-ekscluster-01"
  description = "Security Group for EKS Cluster"
  vpc_id      = data.terraform_remote_state.vpc.outputs.network_vpc_id

  dynamic "ingress" {
    for_each = local.settings.eks_cluster_sg_rules
    content {
      from_port       = ingress.value["from_port"]
      to_port         = ingress.value["to_port"]
      protocol        = ingress.value["protocol"]
      security_groups = []
      cidr_blocks     = []
      self            = true
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "secgrp-${local.settings.env}-${local.settings.region}-ekscluster-01"
  }
}

#Security Group for EKS NodeGroups
resource "aws_security_group" "eks_nodegrp_sg" {
  name        = "secgrp-${local.settings.env}-${local.settings.region}-eksnodegrp-01"
  description = "Security Group for EKS node groups"
  vpc_id      = data.terraform_remote_state.vpc.outputs.network_vpc_id

  dynamic "ingress" {
    for_each = local.settings.eks_nodegrp_sg_rules
    content {
      from_port       = ingress.value["from_port"]
      to_port         = ingress.value["to_port"]
      protocol        = ingress.value["protocol"]
      security_groups = [aws_security_group.eks_alb_sg.id]
      cidr_blocks     = []
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "secgrp-${local.settings.env}-${local.settings.region}-eksnodegrp-01"
  }
}
