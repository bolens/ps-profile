

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
                $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegration -ProfileDir $script:ProfileDir -ModuleType 'Documents' -SelectiveModules @(
            'document-common-html.ps1'
            'document-markdown.ps1'
            'document-office-odt.ps1'
            'document-office-ods.ps1'
            'document-office-odp.ps1'
            'document-office-rtf.ps1'
            'document-common-epub.ps1'
            'document-ebook-mobi.ps1'
            'document-office-plaintext.ps1'
            'document-office-orgmode.ps1'
            'document-office-asciidoc.ps1'
            'document-textile.ps1'
            'document-fb2.ps1'
            'document-latex.ps1'
        ) -EnsureDocuments
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

    Context 'HTML conversion utilities' {
        BeforeEach {
            Initialize-DocumentConversionTestStubs
        }

        AfterEach {
            Clear-DocumentConversionTestStubs
        }
        It 'ConvertTo-HtmlFromMarkdown function exists' {
            Get-Command ConvertTo-HtmlFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }
        
        It 'ConvertTo-HtmlFromMarkdown handles missing input file gracefully' {
            Setup-CapturingCommandMock -CommandName 'pandoc'

            $nonExistentFile = Join-Path $TestDrive 'nonexistent.md'
            # Public wrapper catches errors and Write-Errors without rethrowing
            { ConvertTo-HtmlFromMarkdown -InputPath $nonExistentFile -ErrorAction Stop } | Should -Not -Throw
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

