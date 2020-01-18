#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

Set-Location -Path cert:\LocalMachine\My

$region = "ap-northeast-1"
$bucket = "sorah-acmesmith"
$prefix = "private-prod/certs/" 
$cn = "{0}.ds.nkmi.me" -f [System.Net.Dns]::GetHostName()
$pfxPassword = ConvertTo-SecureString -String "notsecret" -AsPlainText -Force
$lastCertificateMarkFile = "C:\AcmesmithCert.txt"

if (Test-Path $lastCertificateMarkFile) {
  $lastCertificate = Get-ChildItem -Path (Get-Content -Path $lastCertificateMarkFile)
} else {
  $lastCertificate = $null
}

Import-Module AWSPowershell

# In powershell 4.x or earlier
# [System.IO.FileInfo]([System.IO.Path]::GetTempFileName())
$currentFile = New-TemporaryFile
Read-S3Object -Region $region -BucketName $bucket -Key ("{0}{1}/current" -f $prefix,$cn) -File $currentFile
$current =  Get-Content $currentFile

$pfxKey = "{0}{1}/{2}/cert.p12" -f $prefix,$cn,$current
$chainKey = "{0}{1}/{2}/chain.pem" -f $prefix,$cn,$current

$pfxFile = New-TemporaryFile
Read-S3Object -Region $region -BucketName $bucket -Key $pfxKey -File $pfxFile

$chainFile = New-TemporaryFile
Read-S3Object -Region $region -BucketName $bucket -Key $chainKey -File $chainFile

$cert = Import-PfxCertificate -Password $pfxPassword -FilePath $pfxFile.FullName -CertStoreLocation 'cert:\LocalMachine\My'
Remove-Item $pfxFile

$intermediate = Import-Certificate -FilePath $chainFile.FullName -CertStoreLocation 'cert:\LocalMachine\CA'
Write-Output $intermediate
Write-Output $cert

# RDP
# $rdp_wmi = (Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'").__path
# Set-WmiInstance -Path $rdp_wmi -Argument @{SSLCertificateSHA1Hash=$cert.Thumbprint}

# LDAP
$reload_ldif_path = New-TemporaryFile
@'
dn:
changetype: modify
add: renewServerCertificate
renewServerCertificate: 1
'@ | Out-File $reload_ldif_path

# Switch-Certificate

if ($lastCertificate) {
  Write-Output "Switching"
  if ($lastCertificate.Thumbprint -ne $cert.Thumbprint) {
    Switch-Certificate -OldCert $lastCertificate -NewCert $cert
  }
}
$cert.Thumbprint | Out-File $lastCertificateMarkFile

# Remove expired certs

$expiredCerts = Get-ChildItem -Path 'Cert:\LocalMachine\My' -SSLServerAuthentication -ExpiringInDays 0 -DnsName $cert.DnsNameList[0].Unicode
$expiredCerts | Remove-Item -DeleteKey


