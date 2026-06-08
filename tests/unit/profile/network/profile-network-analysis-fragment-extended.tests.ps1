<#
tests/unit/profile-network-analysis-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/network-analysis.ps1'
}
Describe 'profile.d/network-analysis.ps1 extended scenarios' {
    It 'Declares standard tier for network analysis tooling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: server, development'
    }
    It 'Defines Start-Wireshark and documents Register-ToolWrapper pattern' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Start-Wireshark'
        $c | Should -Match 'Register-ToolWrapper'
    }
    It 'Uses Test-FragmentLoaded guard and marks fragment loaded on success' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName 'network-analysis'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'network-analysis'"
    }
}
