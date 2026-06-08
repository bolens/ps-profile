<#
tests/unit/validation-idempotency-fixtures.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-idempotency.ps1 with isolated profile.d fixtures.
#>

function global:New-IdempotencyFixtureRepository {
    param(
        [switch]$IncludeNonIdempotentFragment
    )

    $repo = New-TestTempDirectory -Prefix 'IdempotencyFixtureRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    $checksDir = Join-Path $scriptsDir 'checks'
    New-Item -ItemType Directory -Path $checksDir -Force | Out-Null
    Copy-Item -LiteralPath $script:IdempotencyScript -Destination (Join-Path $checksDir 'check-idempotency.ps1') -Force

    $profileDir = Join-Path $repo 'profile.d'
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $profileDir '00-idempotent.ps1') -Value @'
if (-not (Test-Path Function:\Test-IdempotencyFixturePass)) {
    function Test-IdempotencyFixturePass { 'ok' }
}
'@

    if ($IncludeNonIdempotentFragment) {
        Set-Content -LiteralPath (Join-Path $profileDir '99-non-idempotent.ps1') -Value @'
if ($script:IdempotencyFixtureFailMarker) {
    throw 'Second load detected'
}
$script:IdempotencyFixtureFailMarker = $true
'@
    }

    New-Item -ItemType Directory -Path (Join-Path $repo '.git') -Force | Out-Null

    return $repo
}

function global:Invoke-IdempotencyCheck {
    param(
        [string]$RepositoryRoot
    )

    $scriptPath = Join-Path $RepositoryRoot 'scripts' 'checks' 'check-idempotency.ps1'
    & pwsh -NoProfile -File $scriptPath 2>&1 | Out-Null
    return $LASTEXITCODE
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:IdempotencyScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-idempotency.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-idempotency.ps1 fixture execution' {
    It 'Passes when isolated profile fragments are idempotent' {
        $repo = New-IdempotencyFixtureRepository
        try {
            Invoke-IdempotencyCheck -RepositoryRoot $repo | Should -Be 0
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when a fragment throws on the second dot-source' {
        $repo = New-IdempotencyFixtureRepository -IncludeNonIdempotentFragment
        try {
            Invoke-IdempotencyCheck -RepositoryRoot $repo | Should -BeIn @(1, 2)
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
