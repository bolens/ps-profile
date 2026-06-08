<#
tests/unit/profile-main-loader-scoop-extended.tests.ps1
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
Describe 'Microsoft.PowerShell_profile.ps1 Scoop integration extended scenarios' {
    It 'Documents Scoop package manager integration' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'SCOOP INTEGRATION'
        $c | Should -Match 'ProfileScoop.psm1'
        $c | Should -Match 'Initialize-ProfileScoop'
    }
    It 'Initializes Scoop when profile module is available' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Import-Module .+profileScoopModule'
        $c | Should -Match 'Initialize-ProfileScoop -ProfileDir'
    }
    It 'Warns on Scoop module load failure when debug enabled' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Failed to load ProfileScoop module'
        $c | Should -Match 'PS_PROFILE_DEBUG'
    }
}
