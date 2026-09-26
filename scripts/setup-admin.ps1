$ErrorActionPreference = 'Stop'

$credentialPath = $env:GOOGLE_APPLICATION_CREDENTIALS
if ([string]::IsNullOrWhiteSpace($credentialPath) -or
    -not (Test-Path -LiteralPath $credentialPath -PathType Leaf)) {
  Write-Error 'GOOGLE_APPLICATION_CREDENTIALS must point to your real Firebase service-account JSON file. The C:\path\to\service-account.json example is not a file.'
  exit 1
}

$promptedForPassword = [string]::IsNullOrWhiteSpace($env:BADAL_ADMIN_PASSWORD)
if ($promptedForPassword) {
  $secret = Read-Host 'Admin password' -AsSecureString
  $env:BADAL_ADMIN_PASSWORD = [System.Net.NetworkCredential]::new('', $secret).Password
  $secret.Dispose()
}

$nodeExitCode = 1
try {
  & node (Join-Path $PSScriptRoot 'setup-admin.mjs')
  $nodeExitCode = $LASTEXITCODE
} finally {
  if ($promptedForPassword) {
    Remove-Item Env:BADAL_ADMIN_PASSWORD -ErrorAction SilentlyContinue
  }
}
exit $nodeExitCode
