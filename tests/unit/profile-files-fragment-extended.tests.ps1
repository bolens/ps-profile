<#
tests/unit/profile-files-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files.ps1'
}
Describe 'profile.d/files.ps1 extended scenarios' {
    It 'Declares essential tier depending on bootstrap and env' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Defines Write-SubModuleError for fragment module load failures' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Write-SubModuleError'
        $c | Should -Match 'Write-ProfileError'
    }
    It 'Loads file utilities from files-modules subdirectories' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'files-modules'
    }
    It 'Uses deferred Ensure-FileUtilities loading pattern' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Ensure-FileUtilities'
    }
}
