# ===============================================
# profile-files-module-registry-documents-extended.tests.ps1
# Execution tests for Ensure-FileConversion-Documents registry entries
# ===============================================

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

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
}

Describe 'profile.d/files-module-registry.ps1 Ensure-FileConversion-Documents registry extended scenarios' {
    It 'Maps Ensure-FileConversion-Documents to document conversion modules' {
        $entries = $script:FileConversionModuleRegistry['Ensure-FileConversion-Documents']
        ($entries | Where-Object { $_.Dir -eq 'conversion-modules/document' }).Count | Should -BeGreaterThan 10
    }

    It 'Includes markdown LaTeX and office document modules' {
        $files = $script:FileConversionModuleRegistry['Ensure-FileConversion-Documents'] | ForEach-Object { $_.File }
        $files | Should -Contain 'document-markdown.ps1'
        $files | Should -Contain 'document-latex.ps1'
        $files | Should -Contain 'document-rst.ps1'
        $files | Should -Contain 'document-office-odt.ps1'
        $files | Should -Contain 'document-office-excel.ps1'
        $files | Should -Contain 'document-ebook-mobi.ps1'
    }

    It 'Load-EnsureModules loads document conversion module initializers' {
        Load-EnsureModules -EnsureFunctionName 'Ensure-FileConversion-Documents' -BaseDir $script:ProfileDir

        Get-Command Initialize-FileConversion-DocumentMarkdown -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-FileConversion-DocumentLaTeX -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-FileConversion-DocumentOfficeOdt -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
