<#
tests/unit/profile-files-module-registry-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files-module-registry.ps1'
}
Describe 'profile.d/files-module-registry.ps1 extended scenarios' {
    It 'Documents deferred loading registry for Ensure functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Module Registry for Deferred Loading'
        $c | Should -Match 'loaded on-demand'
    }
    It 'Maps Ensure-FileConversion-Data to conversion-modules entries' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Ensure-FileConversion-Data'
        $c | Should -Match 'conversion-modules/data/core'
    }
    It 'Includes helper modules such as ConversionBase before format modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ConversionBase\.ps1'
        $c | Should -Match 'conversion-modules/helpers'
    }
}
