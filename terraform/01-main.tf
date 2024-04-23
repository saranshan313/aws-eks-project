locals {
  regions = {
    "use1" = "us-east-1"
  }
  settings = yamldecode(file("${var.TFC_WORKSPACE_NAME}.yaml"))
}

provider "aws" {
  region = local.regions[local.settings.region]

  default_tags {
    tags = {
      region = local.settings.region
      env    = local.settings.env
    }
  }
}

provider "kubernetes" {
  host = aws_eks_cluster.eks_apps.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_apps.certificate_authority.data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_apps.id]
    command = "aws"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "tf-remote-state-234-343-555"
    key    = "env:/infra-${local.settings.env}-${local.settings.region}/infra-${local.settings.env}-${local.settings.region}.tfstate"
    region = local.regions[local.settings.region]
  }
}

#data "aws_caller_identity" "current" {}

data "aws_secretsmanager_random_password" "eks_rds" {
  password_length    = 15
  exclude_characters = "`,\"-_''@/\\"
}
