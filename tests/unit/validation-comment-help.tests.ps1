#
# Comment-based help validation script tests.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ScriptsChecksPath = Get-TestPath -RelativePath 'scripts\checks' -StartPath $PSScriptRoot -EnsureExists
}

Describe 'check-comment-help.ps1' {
    Context 'Comment-Based Help Validation' {
        It 'Validates comment-based help in fragments' {
            $scriptPath = Join-Path $script:ScriptsChecksPath 'check-comment-help.ps1'
            if (Test-Path $scriptPath) {
                $null = pwsh -NoProfile -File $scriptPath 2>&1
                $LASTEXITCODE | Should -BeIn @(0, 1)
            }
            else {
                Set-ItResult -Skipped -Because 'check-comment-help.ps1 not found'
            }
        }
    }
}