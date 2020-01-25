resource "aws_ecs_cluster" "cluster" {
  name = var.name
  capacity_providers = [
    aws_ecs_capacity_provider.spot.name,
  ]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.spot.name
    weight            = var.spot_capacity_provider_weight
  }
}

