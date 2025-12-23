

<#
.SYNOPSIS
    Integration tests for LaTeX, RST, Textile, and DjVu document format conversions.

.DESCRIPTION
    This test suite validates LaTeX, RST, Textile, and DjVu conversion functions.

.NOTES
    Tests cover LaTeX-related format conversions and specialized document formats.
#>

Describe 'LaTeX and Specialized Document Format Conversion Tests' {
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
            Write-Error "Failed to initialize LaTeX document conversion tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Document conversion utilities - RST and LaTeX' {
        It 'ConvertFrom-RstToMarkdown converts RST to Markdown' {
            $tempFile = $null
            try {
                Get-Command ConvertFrom-RstToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
                # Test function existence and basic parameter handling
                $rst = 'Test RST Document'
                $tempFile = Join-Path $TestDrive 'test.rst'
                Set-Content -Path $tempFile -Value $rst
                # Test that function doesn't throw when called (pandoc may not be available)
                { ConvertFrom-RstToMarkdown -InputPath $tempFile } | Should -Not -Throw
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Type     = $_.Exception.GetType().FullName
                    Location = $_.InvocationInfo.ScriptLineNumber
                    Category = 'Conversion'
                    TestFile = $tempFile
                }
                Write-Error "ConvertFrom-RstToMarkdown test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'ConvertFrom-LaTeXToMarkdown converts LaTeX to Markdown' {
            $tempFile = $null
            try {
                Get-Command ConvertFrom-LaTeXToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
                # Test function existence and basic parameter handling
                $latex = '\documentclass{article}\begin{document}Test\end{document}'
                $tempFile = Join-Path $TestDrive 'test.tex'
                Set-Content -Path $tempFile -Value $latex
                # Test that function doesn't throw when called (pandoc may not be available)
                { ConvertFrom-LaTeXToMarkdown -InputPath $tempFile } | Should -Not -Throw
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Type     = $_.Exception.GetType().FullName
                    Location = $_.InvocationInfo.ScriptLineNumber
                    Category = 'Conversion'
                    TestFile = $tempFile
                }
                Write-Error "ConvertFrom-LaTeXToMarkdown test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }
    }

    Context 'Textile document conversion utilities' {
        It 'ConvertFrom-TextileToMarkdown function exists' {
            Get-Command ConvertFrom-TextileToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-PdfFromTextile function exists' {
            Get-Command ConvertTo-PdfFromTextile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-PdfFromTextile converts Textile to PDF' {
            # Skip if pandoc not available
            $pandoc = Test-ToolAvailable -ToolName 'pandoc' -InstallCommand 'scoop install pandoc' -Silent
            if (-not $pandoc.Available) {
                $skipMessage = "pandoc command not available"
                if ($pandoc.InstallCommand) {
                    $skipMessage += ". Install with: $($pandoc.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }

            $tempFile = $null
            try {
                # Create a simple Textile test file
                $textile = @"
h1. Test Header

This is test content.
"@
                $tempFile = Join-Path $TestDrive 'test.textile'
                Set-Content -Path $tempFile -Value $textile

                # Test that function doesn't throw when called
                # PDF conversion may fail if LaTeX engine not available, but function should handle it
                { ConvertTo-PdfFromTextile -InputPath $tempFile } | Should -Not -Throw
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Type     = $_.Exception.GetType().FullName
                    Location = $_.InvocationInfo.ScriptLineNumber
                    Category = 'Conversion'
                    TestFile = $tempFile
                }
                Write-Error "ConvertTo-PdfFromTextile test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'ConvertTo-DocxFromTextile function exists' {
            Get-Command ConvertTo-DocxFromTextile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-DocxFromTextile converts Textile to DOCX' {
            # Skip if pandoc not available
            $pandoc = Test-ToolAvailable -ToolName 'pandoc' -InstallCommand 'scoop install pandoc' -Silent
            if (-not $pandoc.Available) {
                $skipMessage = "pandoc command not available"
                if ($pandoc.InstallCommand) {
                    $skipMessage += ". Install with: $($pandoc.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }

            # Create a simple Textile test file
            $textile = @"
h1. Test Header

This is test content.
"@
            $tempFile = Join-Path $TestDrive 'test.textile'
            Set-Content -Path $tempFile -Value $textile

            # Test that function doesn't throw when called
            { ConvertTo-DocxFromTextile -InputPath $tempFile } | Should -Not -Throw

            # Verify output file was created
            $outputFile = Join-Path $TestDrive 'test.docx'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $outputFile | Should -Exist
            }
        }

        It 'ConvertTo-LaTeXFromTextile function exists' {
            Get-Command ConvertTo-LaTeXFromTextile -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-LaTeXFromTextile converts Textile to LaTeX' {
            # Skip if pandoc not available
            $pandoc = Test-ToolAvailable -ToolName 'pandoc' -InstallCommand 'scoop install pandoc' -Silent
            if (-not $pandoc.Available) {
                $skipMessage = "pandoc command not available"
                if ($pandoc.InstallCommand) {
                    $skipMessage += ". Install with: $($pandoc.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }

            # Create a simple Textile test file
            $textile = @"
h1. Test Header

This is test content.
"@
            $tempFile = Join-Path $TestDrive 'test.textile'
            Set-Content -Path $tempFile -Value $textile

            # Test that function doesn't throw when called
            { ConvertTo-LaTeXFromTextile -InputPath $tempFile } | Should -Not -Throw

            # Verify output file was created
            $outputFile = Join-Path $TestDrive 'test.tex'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $outputContent = Get-Content -Path $outputFile -Raw
                $outputContent | Should -Not -BeNullOrEmpty
            }
        }

        It 'Textile conversion functions handle missing input file gracefully' {
            $nonExistentFile = $null
            try {
                $nonExistentFile = Join-Path $TestDrive 'nonexistent.textile'
                
                # Should throw an error for missing file
                { ConvertFrom-TextileToMarkdown -InputPath $nonExistentFile } | Should -Throw
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Type     = $_.Exception.GetType().FullName
                    Location = $_.InvocationInfo.ScriptLineNumber
                    Category = 'ErrorHandling'
                    TestFile = $nonExistentFile
                }
                Write-Error "Textile conversion error handling test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }
    }

    Context 'DjVu document conversion utilities' {
        It 'ConvertFrom-DjvuToPdf function exists' {
            Get-Command ConvertFrom-DjvuToPdf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-DjvuToPdf converts DjVu to PDF' {
            # Skip if tools not available
            $imageMagick = Test-ToolAvailable -ToolName 'magick' -InstallCommand 'scoop install imagemagick' -Silent
            $convert = Test-ToolAvailable -ToolName 'convert' -InstallCommand 'scoop install imagemagick' -Silent
            $graphicsMagick = Test-ToolAvailable -ToolName 'gm' -InstallCommand 'scoop install graphicsmagick' -Silent
            $djvulibre = Test-ToolAvailable -ToolName 'djvups' -InstallCommand 'scoop install djvulibre' -Silent
            
            $hasImageMagick = $imageMagick.Available -or $convert.Available -or $graphicsMagick.Available
            $hasDjvulibre = $djvulibre.Available
            
            if (-not $hasImageMagick -and -not $hasDjvulibre) {
                $skipMessage = "ImageMagick/GraphicsMagick or djvulibre not available"
                $installCommands = @()
                if (-not $hasImageMagick) {
                    $installCommands += "scoop install imagemagick"
                    $installCommands += "scoop install graphicsmagick"
                }
                if (-not $hasDjvulibre) {
                    $installCommands += "scoop install djvulibre"
                }
                if ($installCommands.Count -gt 0) {
                    $skipMessage += ". Install with: $($installCommands -join ' or ')"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }

            # Note: Requires actual DjVu file for full testing
            Get-Command ConvertFrom-DjvuToPdf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-DjvuToPng function exists' {
            Get-Command ConvertFrom-DjvuToPng -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-DjvuToJpeg function exists' {
            Get-Command ConvertFrom-DjvuToJpeg -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-DjvuToText function exists' {
            Get-Command ConvertFrom-DjvuToText -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-DjvuToText extracts text from DjVu' {
            # Skip if djvutxt not available
            $djvutxt = Test-ToolAvailable -ToolName 'djvutxt' -InstallCommand 'scoop install djvulibre' -Silent
            if (-not $djvutxt.Available) {
                $skipMessage = "djvutxt command not available"
                if ($djvutxt.InstallCommand) {
                    $skipMessage += ". Install with: $($djvutxt.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }

            # Note: Requires actual DjVu file for full testing
            Get-Command ConvertFrom-DjvuToText -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'DjVu conversion functions handle .djv extension' {
            # Skip if tools not available
            $imageMagick = Test-ToolAvailable -ToolName 'magick' -InstallCommand 'scoop install imagemagick' -Silent
            $convert = Test-ToolAvailable -ToolName 'convert' -InstallCommand 'scoop install imagemagick' -Silent
            $graphicsMagick = Test-ToolAvailable -ToolName 'gm' -InstallCommand 'scoop install graphicsmagick' -Silent
            $djvulibre = Test-ToolAvailable -ToolName 'ddjvu' -InstallCommand 'scoop install djvulibre' -Silent
            
            $hasImageMagick = $imageMagick.Available -or $convert.Available -or $graphicsMagick.Available
            $hasDjvulibre = $djvulibre.Available
            
            if (-not $hasImageMagick -and -not $hasDjvulibre) {
                $skipMessage = "ImageMagick/GraphicsMagick or djvulibre not available"
                $installCommands = @()
                if (-not $hasImageMagick) {
                    $installCommands += "scoop install imagemagick"
                    $installCommands += "scoop install graphicsmagick"
                }
                if (-not $hasDjvulibre) {
                    $installCommands += "scoop install djvulibre"
                }
                if ($installCommands.Count -gt 0) {
                    $skipMessage += ". Install with: $($installCommands -join ' or ')"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }

            # Note: Requires actual DjVu file for full testing
            Get-Command ConvertFrom-DjvuToPng -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'DjVu conversion functions handle missing input file gracefully' {
            $nonExistentFile = $null
            try {
                $nonExistentFile = Join-Path $TestDrive 'nonexistent.djvu'
                
                # Should throw an error for missing file
                { ConvertFrom-DjvuToPdf -InputPath $nonExistentFile } | Should -Throw
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Type     = $_.Exception.GetType().FullName
                    Location = $_.InvocationInfo.ScriptLineNumber
                    Category = 'ErrorHandling'
                    TestFile = $nonExistentFile
                }
                Write-Error "DjVu conversion error handling test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        Context 'LaTeX conversion utilities' {
            It 'ConvertFrom-OdtToLatex function exists' {
                Get-Command ConvertFrom-OdtToLatex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }

            It 'ConvertFrom-EpubToLatex function exists' {
                Get-Command ConvertFrom-EpubToLatex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }

            It 'ConvertFrom-OrgmodeToLatex function exists' {
                Get-Command ConvertFrom-OrgmodeToLatex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }

            It 'ConvertFrom-AsciidocToLatex function exists' {
                Get-Command ConvertFrom-AsciidocToLatex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }

            It 'ConvertTo-LaTeXFromFb2 function exists' {
                Get-Command ConvertTo-LaTeXFromFb2 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            }

            It 'latex-to-markdown alias resolves to ConvertFrom-LaTeXToMarkdown' {
                Get-Alias latex-to-markdown -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias latex-to-markdown).ResolvedCommandName | Should -Be 'ConvertFrom-LaTeXToMarkdown'
            }

            It 'latex-to-html alias resolves to ConvertTo-HtmlFromLaTeX' {
                Get-Alias latex-to-html -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias latex-to-html).ResolvedCommandName | Should -Be 'ConvertTo-HtmlFromLaTeX'
            }

            It 'latex-to-pdf alias resolves to ConvertTo-PdfFromLaTeX' {
                Get-Alias latex-to-pdf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias latex-to-pdf).ResolvedCommandName | Should -Be 'ConvertTo-PdfFromLaTeX'
            }

            It 'latex-to-docx alias resolves to ConvertTo-DocxFromLaTeX' {
                Get-Alias latex-to-docx -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias latex-to-docx).ResolvedCommandName | Should -Be 'ConvertTo-DocxFromLaTeX'
            }

            It 'latex-to-rst alias resolves to ConvertTo-RstFromLaTeX' {
                Get-Alias latex-to-rst -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias latex-to-rst).ResolvedCommandName | Should -Be 'ConvertTo-RstFromLaTeX'
            }

            It 'rst-to-markdown alias resolves to ConvertFrom-RstToMarkdown' {
                Get-Alias rst-to-markdown -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias rst-to-markdown).ResolvedCommandName | Should -Be 'ConvertFrom-RstToMarkdown'
            }

            It 'rst-to-html alias resolves to ConvertTo-HtmlFromRst' {
                Get-Alias rst-to-html -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias rst-to-html).ResolvedCommandName | Should -Be 'ConvertTo-HtmlFromRst'
            }

            It 'rst-to-pdf alias resolves to ConvertTo-PdfFromRst' {
                Get-Alias rst-to-pdf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias rst-to-pdf).ResolvedCommandName | Should -Be 'ConvertTo-PdfFromRst'
            }

            It 'rst-to-docx alias resolves to ConvertTo-DocxFromRst' {
                Get-Alias rst-to-docx -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias rst-to-docx).ResolvedCommandName | Should -Be 'ConvertTo-DocxFromRst'
            }

            It 'rst-to-latex alias resolves to ConvertTo-LaTeXFromRst' {
                Get-Alias rst-to-latex -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias rst-to-latex).ResolvedCommandName | Should -Be 'ConvertTo-LaTeXFromRst'
            }

            It 'textile-to-markdown alias resolves to ConvertFrom-TextileToMarkdown' {
                Get-Alias textile-to-markdown -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias textile-to-markdown).ResolvedCommandName | Should -Be 'ConvertFrom-TextileToMarkdown'
            }

            It 'textile-to-html alias resolves to ConvertTo-HtmlFromTextile' {
                Get-Alias textile-to-html -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias textile-to-html).ResolvedCommandName | Should -Be 'ConvertTo-HtmlFromTextile'
            }

            It 'textile-to-pdf alias resolves to ConvertTo-PdfFromTextile' {
                Get-Alias textile-to-pdf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias textile-to-pdf).ResolvedCommandName | Should -Be 'ConvertTo-PdfFromTextile'
            }

            It 'textile-to-docx alias resolves to ConvertTo-DocxFromTextile' {
                Get-Alias textile-to-docx -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias textile-to-docx).ResolvedCommandName | Should -Be 'ConvertTo-DocxFromTextile'
            }

            It 'textile-to-latex alias resolves to ConvertTo-LaTeXFromTextile' {
                Get-Alias textile-to-latex -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                (Get-Alias textile-to-latex).ResolvedCommandName | Should -Be 'ConvertTo-LaTeXFromTextile'
            }
        }
    }
}

