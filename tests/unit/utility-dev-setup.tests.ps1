<#
tests/unit/utility-dev-setup.tests.ps1

.SYNOPSIS
    Behavioral unit tests for scripts/dev/setup.ps1.
#>

function global:Invoke-DevSetupScript {
    $output = & pwsh -NoProfile -File $script:DevSetupScript 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:DevSetupScript = Join-Path $script:TestRepoRoot 'scripts' 'dev' 'setup.ps1'
    $script:DevModulesAvailable = @(
        (Get-Module -ListAvailable -Name Pester)
        (Get-Module -ListAvailable -Name PSScriptAnalyzer)
    ) -notcontains $null
}

Describe 'setup.ps1 execution' {
    It 'Completes successfully when required development modules are available' {
        if (-not $script:DevModulesAvailable) {
            Set-ItResult -Skipped -Because 'Pester or PSScriptAnalyzer is not installed'
            return
        }

        $result = Invoke-DevSetupScript
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Setup Summary:'
        $result.Output | Should -Match 'Installed: 2/2 modules'
    }

    It 'Reports setup summary output' {
        $result = Invoke-DevSetupScript
        $result.Output | Should -Match 'Setting up development environment'
        $result.Output | Should -Match 'Setup Summary:'
    }
}
