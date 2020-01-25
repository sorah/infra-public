resource "aws_launch_template" "ecs" {
  name = "ecs-${var.name}"

  iam_instance_profile {
    name = "ec2-ecs"
  }

  image_id = var.ami_id
  key_name = "sorah-mulberry-rsa"

  vpc_security_group_ids = var.security_group_ids

  tag_specifications {
    resource_type = "instance"
    tags = {
      Role     = "ecs"
      Cluster  = var.name
      Status   = "launching"
      Resident = "permanent"
    }
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
      Role    = "ecs"
      Cluster = var.name
    }
  }

  tags = {
    Role    = "encoder-legacy"
    Cluster = var.name
  }
}
