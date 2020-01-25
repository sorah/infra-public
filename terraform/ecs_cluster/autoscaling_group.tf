resource "aws_autoscaling_group" "asg" {
  name                  = "ecs-${var.name}"
  min_size              = 0
  max_size              = var.asg_max_size
  health_check_type     = "EC2"
  vpc_zone_identifier   = var.subnet_ids
  termination_policies  = ["OldestInstance"]
  protect_from_scale_in = true
  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances",
  ]

  mixed_instances_policy {
    instances_distribution {
      spot_allocation_strategy                 = var.spot_allocation_strategy
      on_demand_base_capacity                  = var.on_demand_base_capacity
      on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity
      # on_demand_allocation_strategy = "prioritized"
      spot_max_price      = var.spot_max_price
      spot_instance_pools = var.spot_instance_pools != 0 ? length(var.instance_types) : (var.spot_allocation_strategy == "lowest-price" ? length(var.instance_types) : 0)
    }
    launch_template {
      launch_template_specification {
        version            = "$Latest"
        launch_template_id = aws_launch_template.ecs.id
      }
      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type     = override.key
          weighted_capacity = override.value
        }
      }
    }
  }

  wait_for_capacity_timeout = 0

  tag {
    key                 = "Role"
    value               = "ecs"
    propagate_at_launch = false
  }
}
