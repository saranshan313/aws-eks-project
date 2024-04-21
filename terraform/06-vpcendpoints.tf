# Security group for interface VPC endpoints
resource "aws_security_group" "interface_vpce_sg" {
  for_each = { for tuple in local.settings.eks_cluster.interface_vpce : tuple.id => tuple }
  name = format(
    "secgrp-%s-%s-vpce-%s-01",
    local.settings.env,
    local.settings.region,
    replace(
      each.key,
      strcontains(each.key, ".") ? "." : null,
      "-"
    )
  )
  description = format(
    "VPC endpoint security group for %s",
    each.key
  )
  vpc_id = data.terraform_remote_state.vpc.outputs.network_vpc_id

  dynamic "ingress" {
    for_each = lookup(each.value, "inbound_ports", ["443"])
    content {
      description = format(
        "Allow access to subnets for %s",
        each.key
      )
      from_port = ingress.value
      to_port   = ingress.value
      protocol  = "tcp"
      cidr_blocks = [
        data.terraform_remote_state.vpc.outputs.network_vpc_cidr
      ]
    }
  }
  tags = {
    Name = format(
      "secgrp-%s-%s-vpce-%s-01",
      local.settings.env,
      local.settings.region,
      replace(
        each.key,
        strcontains(each.key, ".") ? "." : null,
        "-"
      )
    )
  }
}

# Interface VPC endpoints
resource "aws_vpc_endpoint" "eks_cluster_vpce" {
  for_each = { for tuple in local.settings.eks_cluster.interface_vpce : tuple.id => tuple }
  vpc_id   = data.terraform_remote_state.vpc.outputs.network_vpc_id
  service_name = format(
    "com.amazonaws.%s.%s",
    local.regions[local.settings.region],
    each.key
  )
  vpc_endpoint_type = "Interface"
  subnet_ids = [
    for k, v in data.terraform_remote_state.vpc.outputs.network_application_subnets : v
  ]

  security_group_ids = [
    aws_security_group.interface_vpce_sg[each.key].id,
  ]

  private_dns_enabled = true

  tags = {
    Name = format(
      "vpce-%s-%s-%s-01",
      local.settings.env,
      local.settings.region,
      replace(
        each.key,
        strcontains(each.key, ".") ? "." : null,
        "-"
      )
    )
  }
}

#Gateway VPC Endpoints
resource "aws_vpc_endpoint" "vpce_gtw" {
  for_each = { for tuple in local.settings.eks_cluster.gateway_vpce : tuple.id => tuple }
  vpc_id   = data.terraform_remote_state.vpc.outputs.network_vpc_id
  service_name = format(
    "com.amazonaws.%s.%s",
    local.regions[local.settings.region],
    each.key
  )
  #  policy            = contains(keys(each.value), "policy") ? file(lookup(each.value, "policy")) : null
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = format(
      "vpce-%s-%s-%s-01",
      local.settings.env,
      local.settings.region,
      replace(
        each.key,
        strcontains(each.key, ".") ? "." : null,
        "-"
      )
    )
  }
}

locals {
  # iterate over vpc endpoint gateways nested to the list of route table id
  route_table_ids = flatten([
    for tuple in local.settings.eks_cluster.gateway_vpce : [
      for rt in data.terraform_remote_state.vpc.outputs.network_application_route_table_ids : {
        vpc_endpoint_id = tuple.id
        route_table_id  = rt
      }
    ]
  ])
}

resource "aws_vpc_endpoint_route_table_association" "gateway_rt_assoc" {
  for_each = { for k in nonsensitive(local.route_table_ids) : format("%s-%s", k.route_table_id, k.vpc_endpoint_id) =>
    {
      vpce_id = k.vpc_endpoint_id
      rt_id   = k.route_table_id
    }
  }

  vpc_endpoint_id = aws_vpc_endpoint.vpce_gtw[each.value["vpce_id"]].id
  route_table_id  = each.value["rt_id"]
}
