<#
tests/unit/utility-debug-diagnose-profile-loading-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for scripts/utils/debug/diagnose-profile-loading.ps1.
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/debug/diagnose-profile-loading.ps1'
}
Describe 'diagnose-profile-loading.ps1 extended scenarios' {
    It 'Prints PowerShell version and edition information' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'PSVersionTable'
        $c | Should -Match 'PSEdition'
    }
    It 'Checks all standard profile path locations' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'CurrentUserAllHosts'
        $c | Should -Match 'CurrentUserCurrentHost'
    }
    It 'Reports whether each profile path exists on disk' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'EXISTS'
        $c | Should -Match 'NOT FOUND'
    }
    It 'Previews active profile file content' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Active Profile'
        $c | Should -Match 'Content Preview'
    }
}
