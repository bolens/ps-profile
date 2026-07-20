#Requires -Version 7.0
<#
.SYNOPSIS
    Dev Container post-create: install CI-aligned PowerShell modules.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host 'Configuring PSGallery...'
if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
    Register-PSRepository -Default
}
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Write-Host 'Installing PSScriptAnalyzer...'
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -AllowClobber

Write-Host 'Installing Pester 5.7.x (CI pin)...'
Install-Module -Name Pester -MinimumVersion 5.7.0 -MaximumVersion 5.7.99 `
    -Scope CurrentUser -Force -AllowClobber
$pester = Get-Module -ListAvailable Pester |
    Where-Object { $_.Version -ge [version]'5.7.0' -and $_.Version -lt [version]'5.8.0' } |
    Sort-Object Version -Descending |
    Select-Object -First 1
if (-not $pester) {
    throw 'Pester 5.7.x is required but was not installed'
}
Import-Module Pester -RequiredVersion $pester.Version -Force

Write-Host "Ready: pwsh $($PSVersionTable.PSVersion) | Pester $($pester.Version)"
Write-Host 'Try: pwsh -NoProfile -File scripts/utils/code-quality/run-pester-ci-shard.ps1 -Shard unit-library -Quiet'
