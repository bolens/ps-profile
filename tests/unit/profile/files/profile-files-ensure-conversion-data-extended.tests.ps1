<#
tests/unit/profile-files-ensure-conversion-data-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files.ps1'
}
Describe 'profile.d/files.ps1 Ensure-FileConversion-Data extended scenarios' {
    It 'Documents lazy data format conversion initializer' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Ensure-FileConversion-Data'
        $c | Should -Match 'data format conversion utility functions on first use'
    }
    It 'Loads modules from registry via Load-EnsureModules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Load-EnsureModules -EnsureFunctionName 'Ensure-FileConversion-Data'"
        $c | Should -Match 'FileConversionDataInitialized'
    }
    It 'Initializes core structured binary columnar and scientific modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreBasicJson'
        $c | Should -Match 'Initialize-FileConversion-ColumnarParquet'
        $c | Should -Match 'Initialize-FileConversion-ScientificHdf5'
    }
}
