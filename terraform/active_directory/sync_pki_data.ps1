#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

$dataDir = 'C:\Windows\System32\CertSrv\CertEnroll'
if ( -Not (Test-Path $dataDir) ) {
  exit 0
}
Set-Location -Path $dataDir

$region = "us-west-2"
$bucket = "nkmi-pki-public"
$prefix = "ad/{0}/" -f [System.Net.Dns]::GetHostName()

$items = Get-ChildItem .\ -Recurse -Include "*.crt","*.crl"
foreach ($item in $items) {
  $key = "{0}{1}" -f $prefix,$item.Name
  Write-Output "{0} => {1}" -f $item.Fullname,$key
  Write-S3Object -Region $region -Bucket $bucket -Key $key -File $item
}


