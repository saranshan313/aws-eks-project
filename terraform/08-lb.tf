# Load Balancer Security Group
resource "aws_security_group" "eks_alb_sg" {
  name        = "secgrp-${local.settings.env}-${local.settings.region}-ekslb-01"
  description = "Security Group for EKS LoadBalancer"
  vpc_id      = data.terraform_remote_state.vpc.outputs.network_vpc_id

  dynamic "ingress" {
    for_each = local.settings.eks_app_lb_sg_rules
    content {
      from_port       = ingress.value["from_port"]
      to_port         = ingress.value["to_port"]
      protocol        = ingress.value["protocol"]
      security_groups = []
      cidr_blocks     = ingress.value["cidr_blocks"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "secgrp-${local.settings.env}-${local.settings.region}-ekslb-01"
  }
}


# EKS Application Load balancer
resource "aws_lb" "ecs_alb" {
  name                             = "alb-${local.settings.env}-${local.settings.region}-eks-alb-01"
  internal                         = local.settings.eks_alb_internal
  load_balancer_type               = local.settings.eks_alb_type
  security_groups                  = [aws_security_group.eks_alb_sg.id]
  subnets                          = [for k, v in data.terraform_remote_state.vpc.outputs.network_public_subnets : v]
  enable_cross_zone_load_balancing = local.settings.eks_alb_crosszone_lb
  ip_address_type                  = local.settings.eks_alb_ip_type

  tags = {
    Name                       = "alb-${local.settings.env}-${local.settings.region}-eks-alb-01"
    "ingress.k8s.aws/stack"    = "alb-${local.settings.env}-${local.settings.region}-ingressalb01", # Kubernetes specific tags for the ingress to choose the ALB
    "ingress.k8s.aws/resource" = "LoadBalancer",                                                    # Kubernetes specific tags for the ingress to choose the ALB
    "elbv2.k8s.aws/cluster"    = "eks-${local.settings.env}-${local.settings.region}-cluster-01"    # Kubernetes specific tags for the ingress to choose the ALB
  }
}

# Target Groups for EKS Application Load Balancer
resource "aws_lb_target_group" "eks_alb_tg" {
  name        = "tg-${local.settings.env}-${local.settings.region}-eks-app-01"
  port        = local.settings.eks_alb_traffic_port
  protocol    = local.settings.eks_alb_protocol
  target_type = local.settings.eks_alb_target_type
  vpc_id      = data.terraform_remote_state.vpc.outputs.network_vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/healthcheck"
    unhealthy_threshold = "2"
  }

  tags = {
    Name = "tg-${local.settings.env}-${local.settings.region}-ecs-app-01"
  }

}

#Listener for EKS Load Balancer
resource "aws_lb_listener" "eks_app_listener" {
  load_balancer_arn = aws_lb.eks_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_alb_tg.id
  }
  tags = {
    Name = "listener-${local.settings.env}-${local.settings.region}-eks-app-01"
  }
}
