<#
tests/unit/profile-main-loader-testpath-interception-extended.tests.ps1
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
Describe 'Microsoft.PowerShell_profile.ps1 Test-Path interception extended scenarios' {
    It 'Documents optional Test-Path interception for debug' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'TEST-PATH INTERCEPTION'
        $c | Should -Match 'PS_PROFILE_DEBUG_TESTPATH'
        $c | Should -Match 'intercept-testpath.ps1'
    }
    It 'Loads interception script when debug flags are set' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Test-Path interception enabled'
        $c | Should -Match 'Loading Test-Path interception script'
    }
    It 'Uses Microsoft.PowerShell.Management Test-Path to avoid recursion' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Management\\Test-Path'
        $c | Should -Match 'interceptScriptPath'
    }
}
