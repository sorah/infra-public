resource "aws_ecs_capacity_provider" "spot" {
  name = "${var.name}-cp-spot"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.asg.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      minimum_scaling_step_size = var.minimum_scaling_step_size
      maximum_scaling_step_size = var.maximum_scaling_step_size
      target_capacity           = var.target_capacity
    }
  }
}
