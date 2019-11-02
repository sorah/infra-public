variable "patch_baseline_id" {}

resource "aws_ssm_patch_group" "patchgroup" {
  baseline_id = var.patch_baseline_id
  patch_group = "ad-dc"
}

# Patch Group should be applied manually via a static tag name "Patch Group" with value "ad-dc"

resource "aws_ssm_maintenance_window_task" "patch" {
  name = "ad-dc-run-patch"

  max_concurrency  = 1
  max_errors       = 1
  priority         = 1
  task_arn         = "AWS-RunPatchBaseline"
  task_type        = "RUN_COMMAND"
  service_role_arn = "${data.aws_iam_role.service_role.arn}"
  window_id        = "${aws_ssm_maintenance_window.default.id}"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.default.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "Operation"
        values = ["Install"]
      }
      parameter {
        name   = "SnapshotId"
        values = ["{{WINDOW_EXECUTION_ID}}"]
      }
    }
  }
}
