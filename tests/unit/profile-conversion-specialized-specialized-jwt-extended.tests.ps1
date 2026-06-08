<#
tests/unit/profile-conversion-specialized-specialized-jwt-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/specialized/specialized-jwt.ps1'
}
Describe 'profile.d/conversion-modules/specialized/specialized-jwt.ps1 extended scenarios' {
    It 'Documents JWT conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'JWT \(JSON Web Token\) conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-SpecializedJwt'
    }
    It 'Defines JSON to JWT and JWT to JSON conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertTo-JwtFromJson'
        $c | Should -Match '_ConvertFrom-JwtToJson'
    }
    It 'Registers json-to-jwt and jwt-to-json aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json-to-jwt'
        $c | Should -Match 'ConvertFrom-JwtToJson'
        $c | Should -Match 'jwt-to-json'
    }
}
