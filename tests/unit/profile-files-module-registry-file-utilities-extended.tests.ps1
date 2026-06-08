<#
tests/unit/profile-files-module-registry-file-utilities-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files-module-registry.ps1'
}
Describe 'profile.d/files-module-registry.ps1 Ensure-FileUtilities registry extended scenarios' {
    It 'Maps Ensure-FileUtilities to files-modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '''Ensure-FileUtilities'''
        $c | Should -Match 'files-modules/inspection'
    }
    It 'Includes inspection utility modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'files-head-tail.ps1'
        $c | Should -Match 'files-hash.ps1'
        $c | Should -Match 'files-hexdump.ps1'
    }
    It 'Includes navigation utility modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'files-modules/navigation'
        $c | Should -Match 'files-listing.ps1'
        $c | Should -Match 'files-navigation.ps1'
    }
}

