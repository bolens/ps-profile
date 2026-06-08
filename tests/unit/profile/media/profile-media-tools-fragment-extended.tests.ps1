<#
tests/unit/profile-media-tools-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/media-tools.ps1'
}
Describe 'profile.d/media-tools.ps1 extended scenarios' {
    It 'Declares optional tier for media processing tooling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match 'ffmpeg'
        $c | Should -Match 'handbrake'
    }
    It 'Defines Convert-Video supporting ffmpeg and handbrake backends' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Convert-Video'
        $c | Should -Match 'UseHandbrake'
    }
    It 'Marks media-tools fragment loaded after helper registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName 'media-tools'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'media-tools'"
    }
}
