

<#
.SYNOPSIS
    Integration tests for HTML document format conversions.

.DESCRIPTION
    This test suite validates HTML conversion functions from various document formats.

.NOTES
    Tests cover HTML conversions from multiple source formats.
#>

Describe 'HTML Document Conversion Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'All' -LoadFilesFragment -EnsureFileConversionDocuments -EnsureFileConversionMedia
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
                Category = 'BeforeAll'
            }
            Write-Error "Failed to initialize HTML document conversion tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'HTML conversion utilities' {
        BeforeEach {
            # Mock external tools to prevent hangs during conversion function calls
            Mock-CommandAvailabilityPester -CommandName 'pandoc' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'pdflatex' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'xelatex' -Available $false -Scope It
            Mock-CommandAvailabilityPester -CommandName 'luatex' -Available $false -Scope It
            Mock -CommandName Get-Command -ParameterFilter { $Name -in @('pandoc', 'pdflatex', 'xelatex', 'luatex') } -MockWith { $null }
            # Mock Ensure-DocumentLatexEngine to return a value without checking (prevent hangs)
            # This function should be loaded by files.ps1 via LoadFilesFragment
            if (Get-Command Ensure-DocumentLatexEngine -ErrorAction SilentlyContinue) {
                Mock -CommandName Ensure-DocumentLatexEngine -MockWith { return 'pdflatex' }
            }
            else {
                # If function doesn't exist, create a simple mock function
                # This handles cases where files.ps1 didn't load LaTeXDetection.ps1
                function global:Ensure-DocumentLatexEngine {
                    return 'pdflatex'
                }
            }
        }
        It 'ConvertTo-HtmlFromMarkdown function exists' {
            Get-Command ConvertTo-HtmlFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }
        
        It 'ConvertTo-HtmlFromMarkdown handles missing input file gracefully' {
            # For this test, mock pandoc as available so the function checks the file first
            Mock-CommandAvailabilityPester -CommandName 'pandoc' -Available $true -Scope It
            
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.md'
            { ConvertTo-HtmlFromMarkdown -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
        }

        It 'ConvertFrom-OdtToHtml function exists' {
            Get-Command ConvertFrom-OdtToHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-OdsToHtml function exists' {
            Get-Command ConvertFrom-OdsToHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-OdpToHtml function exists' {
            Get-Command ConvertFrom-OdpToHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-RtfToHtml function exists' {
            Get-Command ConvertFrom-RtfToHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-EpubToHtml function exists' {
            Get-Command ConvertFrom-EpubToHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-MobiToHtml function exists' {
            Get-Command ConvertFrom-MobiToHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-PlainTextToHtml function exists' {
            Get-Command ConvertFrom-PlainTextToHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-OrgmodeToHtml function exists' {
            Get-Command ConvertFrom-OrgmodeToHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-AsciidocToHtml function exists' {
            Get-Command ConvertFrom-AsciidocToHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-HtmlFromTextile function exists' {
            Get-Command ConvertTo-HtmlFromTextile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-HtmlFromTextile function exists' {
            Get-Command ConvertTo-HtmlFromTextile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-HtmlFromFb2 function exists' {
            Get-Command ConvertTo-HtmlFromFb2 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-PlainTextFromHtml function exists' {
            Get-Command ConvertTo-PlainTextFromHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-EpubFromHtml function exists' {
            Get-Command ConvertTo-EpubFromHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'html-to-markdown alias resolves to ConvertFrom-HtmlToMarkdown' {
            Get-Alias html-to-markdown -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias html-to-markdown).ResolvedCommandName | Should -Be 'ConvertFrom-HtmlToMarkdown'
        }

        It 'html-to-pdf alias resolves to ConvertTo-PdfFromHtml' {
            Get-Alias html-to-pdf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias html-to-pdf).ResolvedCommandName | Should -Be 'ConvertTo-PdfFromHtml'
        }

        It 'html-to-latex alias resolves to ConvertTo-LaTeXFromHtml' {
            Get-Alias html-to-latex -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias html-to-latex).ResolvedCommandName | Should -Be 'ConvertTo-LaTeXFromHtml'
        }
    }
}

