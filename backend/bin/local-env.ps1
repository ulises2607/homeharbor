param([ValidateSet('development', 'test')][string]$Environment = 'development')
# Optional helper for the portable tools prepared in this workspace.
# Dot-source this file so the variables remain in the current PowerShell session.
$toolsRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../.tools'))
$rubyBin = Join-Path $toolsRoot 'rubyinstaller-4.0.9-1-x64/bin'
$nodeBin = Join-Path $toolsRoot 'node-v26.13.1-win-x64'
$pgBin = Join-Path $toolsRoot 'pgsql/bin'
$pwFile = Join-Path $toolsRoot 'postgres-test-password'
foreach ($required in @("$rubyBin/ruby.exe", "$nodeBin/node.exe", "$pgBin/psql.exe", $pwFile)) {
  if (-not (Test-Path -LiteralPath $required)) {
    throw 'Portable tools are missing. Follow README.md for a standard installation.'
  }
}
$env:Path = "$rubyBin;$nodeBin;$pgBin;$env:Path"
Remove-Item Env:GEM_HOME,Env:GEM_PATH -ErrorAction SilentlyContinue
$env:BUNDLE_PATH = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../vendor/bundle'))
$env:BUNDLER_VERSION = '4.0.20'
$env:RAILS_ENV = $Environment
$localPassword = [IO.File]::ReadAllText($pwFile)
$env:DATABASE_URL = "postgresql://homeharbor:${localPassword}@127.0.0.1:55432/homeharbor_${Environment}"
Remove-Variable localPassword
$env:GOOGLE_OAUTH_ENABLED = 'false'
Write-Output "Local toolchain selected for $Environment; PostgreSQL port 55432."
