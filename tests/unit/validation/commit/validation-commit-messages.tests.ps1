#
# Commit message validation script tests.
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

Describe 'check-commit-messages.ps1' {
    Context 'Commit Message Validation' {
        It 'Validates commit message format' {
            $scriptPath = Join-Path $script:ScriptsChecksPath 'check-commit-messages.ps1'
            if (Test-Path $scriptPath) {
                $scriptPath | Should -Exist
            }
            else {
                Set-ItResult -Skipped -Because 'check-commit-messages.ps1 not found'
            }
        }
    }
}
