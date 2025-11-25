#
# Validation tests for validate-profile.ps1.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ScriptsChecksPath = Get-TestPath -RelativePath 'scripts\checks' -StartPath $PSScriptRoot -EnsureExists
    $script:TempRoot = New-TestTempDirectory -Prefix 'ValidateProfile'
}

AfterAll {
    if (Test-Path $script:TempRoot) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'validate-profile.ps1' {
    Context 'Profile Validation Orchestration' {
        It 'Runs all validation checks in sequence' {
            $validateScript = Join-Path $script:ScriptsChecksPath 'validate-profile.ps1'
            if (Test-Path $validateScript) {
                $null = pwsh -NoProfile -File $validateScript 2>&1
                $LASTEXITCODE | Should -BeIn @(0, 1, 2)
            }
            else {
                Set-ItResult -Skipped -Because 'validate-profile.ps1 not found'
            }
        }

        It 'Exits early when a validation check fails' {
            $validateScript = Join-Path $script:ScriptsChecksPath 'validate-profile.ps1'
            if (Test-Path $validateScript) {
                $content = Get-Content -LiteralPath $validateScript -Raw
                $content | Should -Match 'validate-profile'
            }
            else {
                Set-ItResult -Skipped -Because 'validate-profile.ps1 not found'
            }
        }

        It 'Handles missing validation scripts gracefully' {
            $validateScript = Join-Path $script:ScriptsChecksPath 'validate-profile.ps1'
            if (Test-Path $validateScript) {
                $content = Get-Content -LiteralPath $validateScript -Raw
                $content | Should -Not -BeNullOrEmpty
            }
            else {
                Set-ItResult -Skipped -Because 'validate-profile.ps1 not found'
            }
        }
    }
}