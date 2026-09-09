# MVPx navigation link smoke tests
# Usage:
#   $env:MVPX_TEST_USER = "you@company.com"
#   $env:MVPX_TEST_PASSWORD = "yourpassword"
#   .\tests\run-nav-tests.ps1
#
# Static only (no login, no Tomcat required for file checks):
#   .\tests\run-nav-tests.ps1 -StaticOnly

param(
    [switch]$StaticOnly,
    [switch]$TechAdmin,
    [string]$BaseUrl = $env:MVPX_BASE_URL,
    [string]$User = $env:MVPX_TEST_USER,
    [string]$Password = $env:MVPX_TEST_PASSWORD
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

# Load tests/.env if present (git-ignored)
$dotenv = Join-Path $PSScriptRoot ".env"
if (Test-Path $dotenv) {
    Get-Content $dotenv | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $val = $matches[2].Trim()
            if (-not (Get-Item "Env:$name" -ErrorAction SilentlyContinue)) {
                Set-Item -Path "Env:$name" -Value $val
            }
        }
    }
    if (-not $User) { $User = $env:MVPX_TEST_USER }
    if (-not $Password) { $Password = $env:MVPX_TEST_PASSWORD }
    if (-not $BaseUrl) { $BaseUrl = $env:MVPX_BASE_URL }
}
if (-not $BaseUrl) { $BaseUrl = "http://localhost:8080/MVPx" }

$pyArgs = @("$root\tests\test_nav_links.py", "--base-url", $BaseUrl)
if ($StaticOnly) { $pyArgs += "--static-only" }
if ($TechAdmin) { $pyArgs += "--tech-admin" }
if ($User) { $pyArgs += @("--user", $User) }
if ($Password) { $pyArgs += @("--password", $Password) }

Write-Host "Running MVPx nav tests..." -ForegroundColor Cyan
python @pyArgs
exit $LASTEXITCODE
