<#
tests/unit/profile-swift-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/swift.ps1'
}
Describe 'profile.d/swift.ps1 extended scenarios' {
    It 'Declares standard tier guarded by swift availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand swift\)'
    }
    It 'Defines Update-SwiftPackages wrapping swift package update' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Update-SwiftPackages'
        $c | Should -Match 'swift package update'
    }
    It 'Registers swift-update and swift-add aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'swift-update'"
        $c | Should -Match "Set-AgentModeAlias -Name 'swift-add'"
    }
}
