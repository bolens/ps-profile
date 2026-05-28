<#
scripts/repro_set_agentmode.ps1

.SYNOPSIS
    Smoke test that verifies Set-AgentModeFunction and Set-AgentModeAlias bootstrap helpers load and work correctly.

.DESCRIPTION
    Sources the bootstrap fragment and then exercises the core idempotency helpers to
    confirm the profile loading infrastructure is functional.
    Used by CI (smoke-check.yml and ci-matrix.yml) to catch regressions in the bootstrap layer.

.NOTES
    Load-order dependency: profile.d/00-bootstrap.ps1 must be parseable and dot-sourceable.
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Verbose 'repro_set_agentmode: starting'

# Resolve repo root relative to this script
$repoRoot = Split-Path -Parent $PSScriptRoot

# Source the bootstrap fragment which defines Set-AgentModeFunction / Set-AgentModeAlias
$bootstrapPath = Join-Path $repoRoot 'profile.d' '00-bootstrap.ps1'
if (-not (Test-Path -LiteralPath $bootstrapPath)) {
    Write-Error "Bootstrap file not found: $bootstrapPath"
    exit 1
}

Write-Verbose "Sourcing bootstrap: $bootstrapPath"
. $bootstrapPath

# Verify the helpers are now available
if (-not (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue)) {
    Write-Error 'Set-AgentModeFunction not available after sourcing 00-bootstrap.ps1'
    exit 1
}
if (-not (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue)) {
    Write-Error 'Set-AgentModeAlias not available after sourcing 00-bootstrap.ps1'
    exit 1
}

Write-Verbose 'Bootstrap helpers confirmed available'

# Exercise idempotency: register the same function twice, ensure no error
Set-AgentModeFunction -Name 'Test-ReproFunc' -Body { param([string]$Val) $Val }
Set-AgentModeFunction -Name 'Test-ReproFunc' -Body { param([string]$Val) $Val }

if (-not (Get-Command Test-ReproFunc -ErrorAction SilentlyContinue)) {
    Write-Error 'Test-ReproFunc was not registered by Set-AgentModeFunction'
    exit 1
}

# Exercise alias registration idempotency
Set-AgentModeAlias -Name 'repro-test-alias' -Target 'Test-ReproFunc'
Set-AgentModeAlias -Name 'repro-test-alias' -Target 'Test-ReproFunc'

Write-Host 'repro_set_agentmode: PASSED' -ForegroundColor Green
exit 0
