<#
tests/unit/profile-git-ensure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/git.ps1'
}
Describe 'profile.d/git.ps1 Ensure-Git extended scenarios' {
    It 'Documents deferred Git module loading' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Git Modules - DEFERRED LOADING'
        $c | Should -Match 'function Ensure-Git'
    }
    It 'References files-module-registry for module mappings' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'files-module-registry.ps1'
        $c | Should -Match 'Load-EnsureModules'
    }
    It 'Registers lazy git shortcuts before full module load' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Register-LazyFunction'
        $c | Should -Match 'Ensure-Git'
        $c | Should -Match 'GitInitialized'
    }
}

