<#
tests/unit/profile-conversion-media-colors-named-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/colors/named.ps1'
}
Describe 'profile.d/conversion-modules/media/colors/named.ps1 extended scenarios' {
    It 'Documents CSS named colors dictionary' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'CSS Named Colors'
        $c | Should -Match 'CSS Color Module Level 4'
    }
    It 'Defines Initialize-FileConversion-MediaColorsNamed with CssNamedColors table' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-MediaColorsNamed'
        $c | Should -Match 'CssNamedColors'
    }
    It 'Includes basic palette entries like black white and fuchsia' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '''black'''
        $c | Should -Match '''white'''
        $c | Should -Match '''fuchsia'''
    }
}
