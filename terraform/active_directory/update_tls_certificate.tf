data "local_file" "update_tls_certificate_ps1" {
  filename = "${path.module}/update_tls_certificate.ps1"
}

resource "aws_ssm_association" "update_tls_certificate" {
  association_name = "ad-dc-update-tls-certificate"
  name             = "AWS-RunPowerShellScript"

  targets {
    key    = "tag:Role"
    values = ["ad-dc"]
  }

  parameters = {
    commands         = data.local_file.update_tls_certificate_ps1.content
    workingDirectory = "C:\\"
    executionTimeout = "600"
  }
}
