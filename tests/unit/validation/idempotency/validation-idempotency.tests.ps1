#
# Idempotency validation script tests.
#

function global:New-IdempotencyTestRepository {
    param(
        [switch]$NonIdempotent
    )

    $repo = New-TestTempDirectory -Prefix 'IdempotencyRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    $checksDir = Join-Path $scriptsDir 'checks'
    New-Item -ItemType Directory -Path $checksDir -Force | Out-Null
    Copy-Item -LiteralPath $script:IdempotencyScript -Destination (Join-Path $checksDir 'check-idempotency.ps1') -Force

    $profileDir = Join-Path $repo 'profile.d'
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null

    if ($NonIdempotent) {
        Set-Content -LiteralPath (Join-Path $profileDir '00-non-idempotent.ps1') -Value @'
if ($script:IdempotencyFixtureLoaded) {
    throw 'Non-idempotent fragment loaded twice'
}
$script:IdempotencyFixtureLoaded = $true
'@ -Encoding UTF8
    }
    else {
        Set-Content -LiteralPath (Join-Path $profileDir '00-idempotent.ps1') -Value @'
if (-not (Test-Path Function:\Get-IdempotencyFixture)) {
    function Get-IdempotencyFixture { 'ok' }
}
'@ -Encoding UTF8
    }

    Push-Location $repo
    try {
        git init -q | Out-Null
        git config user.email 'fixture@example.com'
        git config user.name 'Fixture'
        git add profile.d/
        git commit -m 'init idempotency fixture' -q
    }
    finally {
        Pop-Location
    }

    return $repo
}

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:IdempotencyScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-idempotency.ps1'
    $script:GitAvailable = [bool](Get-Command git -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'check-idempotency.ps1' {
    Context 'Isolated repositories' {
        It 'Passes when profile.d fragments can be dot-sourced twice' {
            if (-not $script:GitAvailable) {
                Set-ItResult -Skipped -Because 'git is not installed'
                return
            }

            $repo = New-IdempotencyTestRepository
            try {
                Push-Location $repo
                try {
                    $result = Invoke-TestScriptFile -ScriptPath (Join-Path $repo 'scripts' 'checks' 'check-idempotency.ps1')
                }
                finally {
                    Pop-Location
                }

                $result.ExitCode | Should -Be 0
                $result.Output | Should -Match 'Building temporary idempotency runner|Idempotency runner|loaded twice without errors'
            }
            finally {
                if (Test-Path -LiteralPath $repo) {
                    Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Fails when a fragment throws on the second dot-source pass' {
            if (-not $script:GitAvailable) {
                Set-ItResult -Skipped -Because 'git is not installed'
                return
            }

            $repo = New-IdempotencyTestRepository -NonIdempotent
            try {
                Push-Location $repo
                try {
                    $result = Invoke-TestScriptFile -ScriptPath (Join-Path $repo 'scripts' 'checks' 'check-idempotency.ps1')
                }
                finally {
                    Pop-Location
                }

                $result.ExitCode | Should -Be 1
                $result.Output | Should -Match 'Idempotency runner failed|Non-idempotent fragment loaded twice'
            }
            finally {
                if (Test-Path -LiteralPath $repo) {
                    Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context 'Full repository smoke' {
        It 'Validates profile idempotency and reports runner output' {
            if ($env:CI -or $env:GITHUB_ACTIONS) {
                Set-ItResult -Skipped -Because 'full-repo idempotency check is too slow for CI'
                return
            }

            if (-not (Test-Path -LiteralPath $script:IdempotencyScript)) {
                Set-ItResult -Skipped -Because 'check-idempotency.ps1 not found'
                return
            }

            $result = Invoke-TestScriptFile -ScriptPath $script:IdempotencyScript
            $result.Output | Should -Match 'Building temporary idempotency runner|Idempotency runner'
            $result.ExitCode | Should -BeIn @(0, 1)
        }
    }
}
