<#
tests/unit/profile-files-registry-loader-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files.ps1'
}
Describe 'profile.d/files.ps1 files-module-registry loader extended scenarios' {
    It 'Loads files-module-registry via Import-FragmentModule' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'files-module-registry.ps1'
        $c | Should -Match 'Import-FragmentModule'
    }
    It 'Dot-sources registry when standardized loading is unavailable' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'moduleRegistryPath'
        $c | Should -Match '\. \$moduleRegistryPath'
    }
    It 'Defers conversion data documents media and specialized initializers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Ensure-FileConversion-Data'
        $c | Should -Match 'Ensure-FileConversion-Documents'
        $c | Should -Match 'Ensure-FileConversion-Media'
    }
}

