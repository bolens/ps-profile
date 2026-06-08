<#
tests/unit/profile-files-module-registry-media-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files-module-registry.ps1'
}
Describe 'profile.d/files-module-registry.ps1 Ensure-FileConversion-Media registry extended scenarios' {
    It 'Maps Ensure-FileConversion-Media to media modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '''Ensure-FileConversion-Media'''
        $c | Should -Match 'conversion-modules/media'
    }
    It 'Registers image and audio conversion modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'conversion-modules/media/images'
        $c | Should -Match "File = 'flac.ps1'"
        $c | Should -Match "File = 'pdf.ps1'"
    }
    It 'Registers color conversion modules ending with convert' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "File = 'named.ps1'"
        $c | Should -Match "File = 'parse.ps1'"
        $c | Should -Match "File = 'convert.ps1'"
    }
}

