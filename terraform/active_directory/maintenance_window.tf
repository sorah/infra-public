variable "maintenance_window_schedule" {}

resource "aws_ssm_maintenance_window" "default" {
  name     = "active-directory-default"
  schedule = var.maintenance_window_schedule
  duration = 3
  cutoff   = 1
}

resource "aws_ssm_maintenance_window_target" "default" {
  window_id     = "${aws_ssm_maintenance_window.default.id}"
  name          = "active-directory-default"
  description   = "ad-dc"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Role"
    values = ["ad-dc"]
  }
}
