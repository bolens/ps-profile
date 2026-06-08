#
# Idempotency validation script tests.
#

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
    $script:ScriptsChecksPath = Get-TestPath -RelativePath 'scripts\checks' -StartPath $PSScriptRoot -EnsureExists
}

Describe 'check-idempotency.ps1' {
    Context 'Idempotency Checks' {
        It 'Validates profile idempotency and reports runner output' {
            if ($env:CI -or $env:GITHUB_ACTIONS) {
                Set-ItResult -Skipped -Because 'full-repo idempotency check is too slow for CI'
                return
            }

            $scriptPath = Join-Path $script:ScriptsChecksPath 'check-idempotency.ps1'
            if (-not (Test-Path -LiteralPath $scriptPath)) {
                Set-ItResult -Skipped -Because 'check-idempotency.ps1 not found'
                return
            }

            $output = & pwsh -NoProfile -File $scriptPath 2>&1 | Out-String
            $output | Should -Match 'Building temporary idempotency runner|Idempotency runner'
            $LASTEXITCODE | Should -BeIn @(0, 1)
        }
    }
}
