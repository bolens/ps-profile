<#
tests/unit/profile-files-module-registry-data-extended.tests.ps1
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
Describe 'profile.d/files-module-registry.ps1 Ensure-FileConversion-Data registry extended scenarios' {
    It 'Maps Ensure-FileConversion-Data to conversion modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '''Ensure-FileConversion-Data'''
        $c | Should -Match 'conversion-modules/data'
    }
    It 'Includes core and helper conversion modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ConversionBase.ps1'
        $c | Should -Match 'helpers-xml.ps1'
        $c | Should -Match 'File = ''csv.ps1'''
    }
    It 'Includes scientific database and network modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'scientific-hdf5.ps1'
        $c | Should -Match 'database-sqlite.ps1'
        $c | Should -Match 'network-url-uri.ps1'
    }
}
