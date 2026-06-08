<#
tests/unit/profile-aws-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/aws.ps1'
}
Describe 'profile.d/aws.ps1 extended scenarios' {
    It 'Declares standard tier for cloud and development AWS helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: cloud, development'
    }
    It 'Defines Invoke-Aws guarded by Test-CachedCommand aws availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-Aws'
        $c | Should -Match 'Test-CachedCommand aws'
    }
    It 'Documents PowerShell.Profile.Aws module metadata in comment help' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PowerShell.Profile.Aws'
    }
}
