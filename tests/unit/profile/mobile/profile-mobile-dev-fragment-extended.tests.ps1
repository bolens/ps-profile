<#
tests/unit/profile-mobile-dev-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/mobile-dev.ps1'
}
Describe 'profile.d/mobile-dev.ps1 extended scenarios' {
    It 'Declares optional tier for Android and iOS development tooling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match 'Android Studio'
        $c | Should -Match 'scrcpy'
    }
    It 'Defines Connect-AndroidDevice for ADB USB and network connections' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Connect-AndroidDevice'
        $c | Should -Match 'ADB'
    }
    It 'Marks mobile-dev fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName 'mobile-dev'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'mobile-dev'"
    }
}
