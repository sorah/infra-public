data "local_file" "sync_pki_data_ps1" {
  filename = "${path.module}/sync_pki_data.ps1"
}

resource "aws_ssm_association" "sync_pki_data" {
  association_name = "ad-cs-sync-pki-data"
  name             = "AWS-RunPowerShellScript"

  targets {
    key    = "tag:Role"
    values = ["ad-dc"]
  }

  schedule_expression = "rate(2 hours)"

  parameters = {
    commands         = data.local_file.sync_pki_data_ps1.content
    workingDirectory = "C:\\"
    executionTimeout = "600"
  }
}
