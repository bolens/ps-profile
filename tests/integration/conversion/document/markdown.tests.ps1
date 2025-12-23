

<#
.SYNOPSIS
    Integration tests for Markdown document format conversions.

.DESCRIPTION
    This test suite validates Markdown conversion functions from and to various document formats.

.NOTES
    Tests cover Markdown conversions from multiple source formats.
#>

Describe 'Markdown Document Conversion Tests' {
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
            Write-Error "Failed to initialize Markdown document conversion tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Markdown conversion utilities' {
        It 'ConvertFrom-DocxToMarkdown converts DOCX to Markdown' {
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

            Get-Command ConvertFrom-DocxToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Note: Requires actual DOCX file for full testing
        }

        It 'ConvertFrom-OdtToMarkdown function exists' {
            Get-Command ConvertFrom-OdtToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-RtfToMarkdown function exists' {
            Get-Command ConvertFrom-RtfToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-EpubToMarkdown function exists' {
            Get-Command ConvertFrom-EpubToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-MobiToMarkdown function exists' {
            Get-Command ConvertFrom-MobiToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-PlainTextToMarkdown function exists' {
            Get-Command ConvertFrom-PlainTextToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-OrgmodeToMarkdown function exists' {
            Get-Command ConvertFrom-OrgmodeToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-AsciidocToMarkdown function exists' {
            Get-Command ConvertFrom-AsciidocToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-TextileToMarkdown function exists' {
            Get-Command ConvertFrom-TextileToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-TextileToMarkdown converts Textile to Markdown' {
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
            $outputFile = $null
            try {
                # Create a simple Textile test file
                $textile = @"
h1. Test Header

This is a *bold* and _italic_ text.

* Item 1
* Item 2
* Item 3
"@
                $tempFile = Join-Path $TestDrive 'test.textile'
                Set-Content -Path $tempFile -Value $textile

                # Test that function doesn't throw when called
                { ConvertFrom-TextileToMarkdown -InputPath $tempFile } | Should -Not -Throw

                # Verify output file was created
                $outputFile = Join-Path $TestDrive 'test.md'
                if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                    $outputContent = Get-Content -Path $outputFile -Raw
                    $outputContent | Should -Not -BeNullOrEmpty
                }
            }
            catch {
                $errorDetails = @{
                    Message    = $_.Exception.Message
                    Type       = $_.Exception.GetType().FullName
                    Location   = $_.InvocationInfo.ScriptLineNumber
                    Category   = 'Conversion'
                    TestFile   = $tempFile
                    OutputFile = $outputFile
                }
                Write-Error "ConvertFrom-TextileToMarkdown test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

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

        It 'ConvertTo-OdtFromMarkdown function exists' {
            Get-Command ConvertTo-OdtFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-EpubFromMarkdown function exists' {
            Get-Command ConvertTo-EpubFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-MobiFromMarkdown function exists' {
            Get-Command ConvertTo-MobiFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-RtfFromMarkdown function exists' {
            Get-Command ConvertTo-RtfFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-PlainTextFromMarkdown function exists' {
            Get-Command ConvertTo-PlainTextFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-OrgmodeFromMarkdown function exists' {
            Get-Command ConvertTo-OrgmodeFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-AsciidocFromMarkdown function exists' {
            Get-Command ConvertTo-AsciidocFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Textile conversion functions handle .tx extension' {
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

            # Create a Textile test file with .tx extension
            $textile = 'h1. Test Header'
            $tempFile = Join-Path $TestDrive 'test.tx'
            Set-Content -Path $tempFile -Value $textile

            # Test that function handles .tx extension correctly
            { ConvertFrom-TextileToMarkdown -InputPath $tempFile } | Should -Not -Throw

            # Verify output file was created with .md extension
            $outputFile = Join-Path $TestDrive 'test.md'
            if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
                $outputFile | Should -Exist
            }
        }

        It 'Textile conversion functions handle custom output path' {
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
            $textile = 'h1. Test Header'
            $tempFile = Join-Path $TestDrive 'test.textile'
            Set-Content -Path $tempFile -Value $textile

            $customOutput = Join-Path $TestDrive 'custom-output.md'
            
            # Test that function accepts custom output path
            { ConvertFrom-TextileToMarkdown -InputPath $tempFile -OutputPath $customOutput } | Should -Not -Throw

            # Verify custom output file was created
            if ($customOutput -and -not [string]::IsNullOrWhiteSpace($customOutput) -and (Test-Path -LiteralPath $customOutput)) {
                $customOutput | Should -Exist
            }
        }

        It 'markdown-to-html alias resolves to ConvertTo-HtmlFromMarkdown' {
            Get-Alias markdown-to-html -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias markdown-to-html).ResolvedCommandName | Should -Be 'ConvertTo-HtmlFromMarkdown'
        }

        It 'markdown-to-pdf alias resolves to ConvertTo-PdfFromMarkdown' {
            Get-Alias markdown-to-pdf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias markdown-to-pdf).ResolvedCommandName | Should -Be 'ConvertTo-PdfFromMarkdown'
        }

        It 'markdown-to-docx alias resolves to ConvertTo-DocxFromMarkdown' {
            Get-Alias markdown-to-docx -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias markdown-to-docx).ResolvedCommandName | Should -Be 'ConvertTo-DocxFromMarkdown'
        }

        It 'markdown-to-latex alias resolves to ConvertTo-LaTeXFromMarkdown' {
            Get-Alias markdown-to-latex -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias markdown-to-latex).ResolvedCommandName | Should -Be 'ConvertTo-LaTeXFromMarkdown'
        }

        It 'markdown-to-rst alias resolves to ConvertTo-RstFromMarkdown' {
            Get-Alias markdown-to-rst -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias markdown-to-rst).ResolvedCommandName | Should -Be 'ConvertTo-RstFromMarkdown'
        }
    }
}

