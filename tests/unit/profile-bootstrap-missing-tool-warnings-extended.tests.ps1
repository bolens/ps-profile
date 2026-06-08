<#
tests/unit/profile-bootstrap-missing-tool-warnings-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/MissingToolWarnings.ps1'
}
Describe 'profile.d/bootstrap/MissingToolWarnings.ps1 extended scenarios' {
    It 'Documents core missing tool warning utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Core missing tool warning utilities'
        $c | Should -Match 'InstallHintResolver.ps1'
    }
    It 'Defines Get-PlatformSpecificTools with platform mappings' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-PlatformSpecificTools'
        $c | Should -Match 'Test-ToolAvailableOnPlatform'
        $c | Should -Match 'winget'
    }
    It 'Defines Write-MissingToolWarning and Clear-MissingToolWarnings' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Write-MissingToolWarning'
        $c | Should -Match 'Clear-MissingToolWarnings'
    }
}
