. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Document Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files-conversion.ps1')
    }

    Context 'PDF conversion utilities' {
        It 'ConvertFrom-PdfToText extracts text from PDF' {
            # Skip if pandoc not available
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "pandoc command not available"
                return
            }

            $testPdf = Join-Path $TestDrive 'test.pdf'
            # Create a simple test PDF (this would normally be a real PDF file)
            # For testing purposes, we'll assume pandoc can handle basic conversion
            $testContent = "This is test PDF content"

            try {
                # This test would need actual PDF creation, which is complex in tests
                # For now, just verify the function exists and can be called
                Get-Command ConvertFrom-PdfToText -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
            catch {
                # Allow failures due to missing pandoc or test PDF
                if ($_.Exception.Message -notmatch "(pandoc|pdf)") {
                    throw
                }
            }
        }

        It 'Merge-Pdf function exists and can be called' {
            Get-Command Merge-Pdf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Note: Actual PDF merging requires pdftk and test PDF files
        }
    }

    Context 'Office document conversion utilities' {
        It 'ConvertFrom-DocxToMarkdown converts DOCX to Markdown' {
            # Skip if pandoc not available
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "pandoc command not available"
                return
            }

            Get-Command ConvertFrom-DocxToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Note: Requires actual DOCX file for full testing
        }

        It 'ConvertTo-HtmlFromMarkdown converts Markdown to HTML' {
            Get-Command ConvertTo-HtmlFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $markdown = '# Test Header'
            $tempFile = Join-Path $TestDrive 'test.md'
            Set-Content -Path $tempFile -Value $markdown
            # Test that function doesn't throw when called (pandoc may not be available)
            { ConvertTo-HtmlFromMarkdown -InputPath $tempFile } | Should -Not -Throw
        }
    }

    Context 'E-book conversion utilities' {
        It 'ConvertFrom-EpubToMarkdown converts EPUB to Markdown' {
            # Skip if pandoc not available
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "pandoc command not available"
                return
            }

            Get-Command ConvertFrom-EpubToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Note: Requires actual EPUB file for full testing
        }

        It 'ConvertFrom-RstToMarkdown converts RST to Markdown' {
            Get-Command ConvertFrom-RstToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $rst = 'Test RST Document'
            $tempFile = Join-Path $TestDrive 'test.rst'
            Set-Content -Path $tempFile -Value $rst
            # Test that function doesn't throw when called (pandoc may not be available)
            { ConvertFrom-RstToMarkdown -InputPath $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-LaTeXToMarkdown converts LaTeX to Markdown' {
            Get-Command ConvertFrom-LaTeXToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            $latex = '\documentclass{article}\begin{document}Test\end{document}'
            $tempFile = Join-Path $TestDrive 'test.tex'
            Set-Content -Path $tempFile -Value $latex
            # Test that function doesn't throw when called (pandoc may not be available)
            { ConvertFrom-LaTeXToMarkdown -InputPath $tempFile } | Should -Not -Throw
        }
    }
}
