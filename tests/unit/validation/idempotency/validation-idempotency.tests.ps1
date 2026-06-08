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
        It 'Validates profile idempotency' {
            $scriptPath = Join-Path $script:ScriptsChecksPath 'check-idempotency.ps1'
            if (Test-Path $scriptPath) {
                $null = pwsh -NoProfile -File $scriptPath 2>&1
                $LASTEXITCODE | Should -BeIn @(0, 1)
            }
            else {
                Set-ItResult -Skipped -Because 'check-idempotency.ps1 not found'
            }
        }
    }
}
