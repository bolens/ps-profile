<#
tests/unit/profile-pixi-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/pixi.ps1'
}
Describe 'profile.d/pixi.ps1 extended scenarios' {
    It 'Declares standard tier guarded by pixi availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand pixi\)'
    }
    It 'Defines Invoke-PixiInstall and Invoke-PixiRun environment helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-PixiInstall'
        $c | Should -Match 'Invoke-PixiRun'
    }
    It 'Registers pxadd and pxrun shorthand aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-Alias -Name pxadd"
        $c | Should -Match "Set-Alias -Name pxrun"
    }
}
