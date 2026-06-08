<#
tests/unit/profile-files-module-registry-devtools-extended.tests.ps1
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
Describe 'profile.d/files-module-registry.ps1 Ensure-DevTools registry extended scenarios' {
    It 'Maps Ensure-DevTools to dev-tools-modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '''Ensure-DevTools'''
        $c | Should -Match 'dev-tools-modules/encoding'
    }
    It 'Includes crypto and formatting dev tool modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'dev-tools-modules/crypto'
        $c | Should -Match "File = 'hash.ps1'"
        $c | Should -Match "File = 'diff.ps1'"
    }
    It 'Includes qrcode and data dev tool modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'dev-tools-modules/format/qrcode'
        $c | Should -Match "File = 'qrcode.ps1'"
        $c | Should -Match "File = 'units.ps1'"
    }
}

