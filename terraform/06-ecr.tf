#Image repository for ECS application
resource "aws_ecr_repository" "eks_app" {
  name = "repo-${local.settings.env}-${local.settings.region}-eksapp-01"

  image_scanning_configuration {
    scan_on_push = local.settings.ecr_eks.scan_on_push
  }

  tags = {
    Name = "repo-${local.settings.env}-${local.settings.region}-eksapp-01"
  }
}
