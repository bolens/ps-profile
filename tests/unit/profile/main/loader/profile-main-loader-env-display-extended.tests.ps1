<#
tests/unit/profile-main-loader-env-display-extended.tests.ps1
#>
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
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 profile env display extended scenarios' {
    It 'Documents debug env variable display section' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'DISPLAY PS_PROFILE ENVIRONMENT VARIABLES'
        $c | Should -Match 'ProfileEnvDisplay.psm1'
    }
    It 'Calls Show-ProfileEnvVariables when module loads' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Show-ProfileEnvVariables'
        $c | Should -Match 'Import-Module .+profileEnvDisplayModule'
    }
    It 'Warns on env display module load failure when debug enabled' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Failed to load ProfileEnvDisplay module'
        $c | Should -Match 'PS_PROFILE_DEBUG'
    }
}
