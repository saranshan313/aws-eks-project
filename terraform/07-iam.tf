#EKS Cluster Role and Policy
data "aws_iam_policy_document" "eks_cluster_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "role-${local.settings.env}-${local.settings.region}-cluster-role-01"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role_policy.json
  tags = {
    Name = "role-${local.settings.env}-${local.settings.region}-cluster-role-01"
  }
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

#OIDC Provider for EKS Cluster
data "tls_certificate" "eksapps" {
  url = aws_eks_cluster.eks_apps.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list = [
    "sts.amazonaws.com"
  ]
  thumbprint_list = data.tls_certificate.eksapps.certificates[*].sha1_fingerprint
  url             = aws_eks_cluster.eks_apps.identity[0].oidc[0].issuer

  tags = {
    Name = "oidc-${local.settings.env}-${local.settings.region}-eks-cluster-01"
  }
}

#Node Group Role and Policy
data "aws_iam_policy_document" "eks_node_grp_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "node_group_role" {
  name               = "role-${local.settings.env}-${local.settings.region}-nodegrp-01"
  assume_role_policy = data.aws_iam_policy_document.eks_node_grp_assume_role_policy.json

  tags = {
    Name = "role-${local.settings.env}-${local.settings.region}-nodegrp-01"
  }
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group_role.name
}