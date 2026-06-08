<#
tests/unit/profile-files-module-registry-git-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files-module-registry.ps1'
}
Describe 'profile.d/files-module-registry.ps1 Ensure-Git registry extended scenarios' {
    It 'Maps Ensure-Git to git-modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '''Ensure-Git'''
        $c | Should -Match 'git-modules/core'
    }
    It 'Includes core git helper modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'git-helpers.ps1'
        $c | Should -Match 'git-basic.ps1'
        $c | Should -Match 'git-advanced.ps1'
    }
    It 'Includes GitHub integration module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'git-modules/integrations'
        $c | Should -Match 'git-github.ps1'
    }
}

