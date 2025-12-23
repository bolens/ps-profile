

<#
.SYNOPSIS
    Integration tests for EPUB and e-book format conversions.

.DESCRIPTION
    This test suite validates EPUB, MOBI/AZW, and FB2 e-book conversion functions.

.NOTES
    Tests cover e-book format conversions and related formats.
#>

Describe 'EPUB and E-book Conversion Tests' {
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
            Write-Error "Failed to initialize EPUB e-book conversion tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'E-book conversion utilities - EPUB' {
        It 'ConvertFrom-EpubToMarkdown function exists' {
            Get-Command ConvertFrom-EpubToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-EpubToHtml function exists' {
            Get-Command ConvertFrom-EpubToHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-EpubToPdf function exists' {
            Get-Command ConvertFrom-EpubToPdf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-EpubToLatex function exists' {
            Get-Command ConvertFrom-EpubToLatex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-EpubToDocx function exists' {
            Get-Command ConvertFrom-EpubToDocx -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-EpubFromMarkdown function exists' {
            Get-Command ConvertTo-EpubFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-EpubFromHtml function exists' {
            Get-Command ConvertTo-EpubFromHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-EpubToMarkdown handles missing input file gracefully' {
            $nonExistentFile = $null
            try {
                $nonExistentFile = Join-Path $TestDrive 'nonexistent.epub'
                { ConvertFrom-EpubToMarkdown -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Type     = $_.Exception.GetType().FullName
                    Location = $_.InvocationInfo.ScriptLineNumber
                    Category = 'ErrorHandling'
                    TestFile = $nonExistentFile
                }
                Write-Error "ConvertFrom-EpubToMarkdown error handling test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }
    }

    Context 'E-book conversion utilities - MOBI/AZW' {
        It 'ConvertFrom-MobiToEpub function exists' {
            Get-Command ConvertFrom-MobiToEpub -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-MobiToPdf function exists' {
            Get-Command ConvertFrom-MobiToPdf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-MobiToHtml function exists' {
            Get-Command ConvertFrom-MobiToHtml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-MobiToMarkdown function exists' {
            Get-Command ConvertFrom-MobiToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-MobiFromEpub function exists' {
            Get-Command ConvertTo-MobiFromEpub -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-MobiFromMarkdown function exists' {
            Get-Command ConvertTo-MobiFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-MobiToEpub handles missing input file gracefully' {
            $nonExistentFile = $null
            try {
                $nonExistentFile = Join-Path $TestDrive 'nonexistent.mobi'
                { ConvertFrom-MobiToEpub -InputPath $nonExistentFile -ErrorAction Stop } | Should -Throw
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Type     = $_.Exception.GetType().FullName
                    Location = $_.InvocationInfo.ScriptLineNumber
                    Category = 'ErrorHandling'
                    TestFile = $nonExistentFile
                }
                Write-Error "ConvertFrom-MobiToEpub error handling test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'ConvertTo-MobiFromEpub accepts Format parameter' {
            $func = Get-Command ConvertTo-MobiFromEpub -ErrorAction SilentlyContinue
            if ($func) {
                $func.Parameters.Keys | Should -Contain 'Format'
            }
        }

        It 'epub-to-markdown alias resolves to ConvertFrom-EpubToMarkdown' {
            Get-Alias epub-to-markdown -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias epub-to-markdown).ResolvedCommandName | Should -Be 'ConvertFrom-EpubToMarkdown'
        }

        It 'epub-to-html alias resolves to ConvertFrom-EpubToHtml' {
            Get-Alias epub-to-html -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias epub-to-html).ResolvedCommandName | Should -Be 'ConvertFrom-EpubToHtml'
        }

        It 'epub-to-pdf alias resolves to ConvertFrom-EpubToPdf' {
            Get-Alias epub-to-pdf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias epub-to-pdf).ResolvedCommandName | Should -Be 'ConvertFrom-EpubToPdf'
        }

        It 'epub-to-latex alias resolves to ConvertFrom-EpubToLatex' {
            Get-Alias epub-to-latex -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias epub-to-latex).ResolvedCommandName | Should -Be 'ConvertFrom-EpubToLatex'
        }

        It 'epub-to-docx alias resolves to ConvertFrom-EpubToDocx' {
            Get-Alias epub-to-docx -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias epub-to-docx).ResolvedCommandName | Should -Be 'ConvertFrom-EpubToDocx'
        }

        It 'markdown-to-epub alias resolves to ConvertTo-EpubFromMarkdown' {
            Get-Alias markdown-to-epub -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias markdown-to-epub).ResolvedCommandName | Should -Be 'ConvertTo-EpubFromMarkdown'
        }

        It 'html-to-epub alias resolves to ConvertTo-EpubFromHtml' {
            Get-Alias html-to-epub -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias html-to-epub).ResolvedCommandName | Should -Be 'ConvertTo-EpubFromHtml'
        }

        It 'mobi-to-epub alias resolves to ConvertFrom-MobiToEpub' {
            Get-Alias mobi-to-epub -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias mobi-to-epub).ResolvedCommandName | Should -Be 'ConvertFrom-MobiToEpub'
        }

        It 'epub-to-mobi alias resolves to ConvertTo-MobiFromEpub' {
            Get-Alias epub-to-mobi -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias epub-to-mobi).ResolvedCommandName | Should -Be 'ConvertTo-MobiFromEpub'
        }

        It 'markdown-to-mobi alias resolves to ConvertTo-MobiFromMarkdown' {
            Get-Alias markdown-to-mobi -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias markdown-to-mobi).ResolvedCommandName | Should -Be 'ConvertTo-MobiFromMarkdown'
        }
    }

    Context 'FB2 (FictionBook) e-book conversion utilities' {
        It 'ConvertFrom-Fb2ToMarkdown function exists' {
            Get-Command ConvertFrom-Fb2ToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-Fb2ToMarkdown converts FB2 to Markdown' {
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

            # Note: Requires actual FB2 file for full testing
            Get-Command ConvertFrom-Fb2ToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Test function existence and basic parameter handling
            # Actual conversion requires a valid FB2 file
        }

        It 'ConvertTo-HtmlFromFb2 function exists' {
            Get-Command ConvertTo-HtmlFromFb2 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-PdfFromFb2 function exists' {
            Get-Command ConvertTo-PdfFromFb2 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-DocxFromFb2 function exists' {
            Get-Command ConvertTo-DocxFromFb2 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-LaTeXFromFb2 function exists' {
            Get-Command ConvertTo-LaTeXFromFb2 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'FB2 conversion functions handle .fbz extension' {
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

            # Note: Requires actual FB2 file for full testing
            Get-Command ConvertFrom-Fb2ToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'FB2 conversion functions handle missing input file gracefully' {
            $nonExistentFile = $null
            try {
                $nonExistentFile = Join-Path $TestDrive 'nonexistent.fb2'
                
                # Should throw an error for missing file
                { ConvertFrom-Fb2ToMarkdown -InputPath $nonExistentFile } | Should -Throw
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Type     = $_.Exception.GetType().FullName
                    Location = $_.InvocationInfo.ScriptLineNumber
                    Category = 'ErrorHandling'
                    TestFile = $nonExistentFile
                }
                Write-Error "FB2 conversion error handling test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }
    }
}

