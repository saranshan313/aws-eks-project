
resource "aws_security_group" "vpc_endpoints_sg" {
  for_each = { for tuple in local.settings.eks_cluster.vpc_endpoints : tuple.id => tuple }
  name = format(
    "secgrp-%s-%s-vpce-%s-01",
    local.settings.env,
    local.settings.region,
    upper(local.settings.eks_cluster.vpc_endpoints[each.key].id)
  )
  description = format(
    "VPC endpoint security group for %s",
    upper(local.settings.eks_cluster.vpc_endpoints[each.key].id)
  )
  vpc_id = data.terraform_remote_state.vpc.outputs.network_vpc_id

  dynamic "ingress" {
    for_each = lookup(each.value, "inbound_ports", ["443"])
    content {
      description = format(
        "Allow access to subnets for %s",
        upper(local.settings.eks_cluster.vpc_endpoints[each.key].id)
      )
      from_port = ingress.value
      to_port   = ingress.value
      protocol  = "tcp"
      cidr_blocks = [
        data.terraform_remote_state.vpc.outputs.network_vpc_cidr
      ]
    }
  }
}

resource "aws_vpc_endpoint" "eks_cluster_vpce" {
  for_each = { for tuple in local.settings.eks_cluster.vpc_endpoints : tuple.id => tuple }
  vpc_id   = data.terraform_remote_state.vpc.outputs.network_vpc_id
  service_name = format(
    "com.amazonaws.ap-southeast-2.%s",
    local.settings.eks_cluster.vpc_endpoints[each.key].id
  )
  vpc_endpoint_type = "Interface"
  subnet_ids = [
    for k, v in data.terraform_remote_state.vpc.outputs.network_application_subnets : v
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoints_sg[each.key].id,
  ]

  private_dns_enabled = true
}
