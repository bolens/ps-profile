# ===============================================
# profile-files-ensure-conversion-documents-extended.tests.ps1
# Execution tests for files.ps1 Ensure-FileConversion-Documents behavior
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
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'ProfileEnsureDocuments'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'files.ps1')
}

function script:Reset-FileConversionDocumentsState {
    Set-Variable -Name FileConversionDocumentsInitialized -Scope Global -Value $false -Force
}

Describe 'profile.d/files.ps1 Ensure-FileConversion-Documents extended scenarios' {
    BeforeEach {
        Reset-FileConversionDocumentsState
    }

    It 'Registers document conversion helpers through Ensure-FileConversion-Documents' {
        Ensure-FileConversion-Documents

        Get-Command ConvertTo-HtmlFromMarkdown -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ConvertTo-HtmlFromRst -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ConvertTo-PdfFromLaTeX -ErrorAction Stop | Should -Not -BeNullOrEmpty
        $global:FileConversionDocumentsInitialized | Should -Be $true
    }

    It 'ConvertTo-HtmlFromMarkdown accepts a markdown file without throwing' {
        $tempFile = Join-Path $script:TestTempRoot 'ensure-documents.md'
        Set-Content -Path $tempFile -Value '# Ensure Documents Test' -NoNewline

        { ConvertTo-HtmlFromMarkdown -InputPath $tempFile } | Should -Not -Throw
    }

    It 'Skips re-initialization when document conversion is already loaded' {
        Ensure-FileConversion-Documents
        $firstMarkdown = Get-Command ConvertTo-HtmlFromMarkdown -ErrorAction Stop

        Ensure-FileConversion-Documents

        (Get-Command ConvertTo-HtmlFromMarkdown -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstMarkdown.ScriptBlock.ToString()
    }
}
