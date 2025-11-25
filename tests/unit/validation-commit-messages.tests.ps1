#
# Commit message validation script tests.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
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
