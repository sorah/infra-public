resource "aws_ecs_task_definition" "cadvisor" {
  family                = "cadvisor-${var.name}"
  container_definitions = file("${path.module}/cadvisor_containers.json")
  volume {
    name      = "rootfs"
    host_path = "/"
  }
  volume {
    name      = "run"
    host_path = "/run"
  }
  volume {
    name      = "sys"
    host_path = "/sys"
  }
  volume {
    name      = "docker"
    host_path = "/mnt/vol/docker"
  }
  volume {
    name      = "dev-disk"
    host_path = "/dev/disk"
  }
}

resource "aws_ecs_service" "cadvisor" {
  name                = "cadvisor-${var.name}"
  cluster             = aws_ecs_cluster.cluster.name
  task_definition     = aws_ecs_task_definition.cadvisor.arn
  scheduling_strategy = "DAEMON"
  launch_type         = "EC2" # https://github.com/aws/containers-roadmap/issues/692
}
