<#
tests/unit/profile-files-ensure-conversion-documents-extended.tests.ps1
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
Describe 'profile.d/files.ps1 Ensure-FileConversion-Documents extended scenarios' {
    It 'Documents lazy document format conversion initializer' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Ensure-FileConversion-Documents'
        $c | Should -Match 'document format conversion utility functions on first use'
    }
    It 'Loads document modules from registry on first use' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Load-EnsureModules -EnsureFunctionName ''Ensure-FileConversion-Documents'''
        $c | Should -Match 'FileConversionDocumentsInitialized'
    }
    It 'Initializes markdown latex and office document modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentMarkdown'
        $c | Should -Match 'Initialize-FileConversion-DocumentLaTeX'
        $c | Should -Match 'Initialize-FileConversion-DocumentOfficeOdt'
    }
}

