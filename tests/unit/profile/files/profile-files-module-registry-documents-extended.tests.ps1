<#
tests/unit/profile-files-module-registry-documents-extended.tests.ps1
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
Describe 'profile.d/files-module-registry.ps1 Ensure-FileConversion-Documents registry extended scenarios' {
    It 'Maps Ensure-FileConversion-Documents to document modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '''Ensure-FileConversion-Documents'''
        $c | Should -Match 'conversion-modules/document'
    }
    It 'Includes markdown and LaTeX document modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'document-markdown.ps1'
        $c | Should -Match 'document-latex.ps1'
        $c | Should -Match 'document-rst.ps1'
    }
    It 'Includes office and ebook document modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'document-office-odt.ps1'
        $c | Should -Match 'document-office-excel.ps1'
        $c | Should -Match 'document-ebook-mobi.ps1'
    }
}

