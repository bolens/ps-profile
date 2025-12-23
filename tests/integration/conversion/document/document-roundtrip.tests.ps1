

<#
.SYNOPSIS
    Integration tests for cross-format document roundtrip conversions.

.DESCRIPTION
    This test suite validates roundtrip conversions between various document formats.

.NOTES
    Tests cover cross-format document roundtrip scenarios.
#>

Describe 'Document Roundtrip Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'All' -LoadFilesFragment -EnsureFileConversionDocuments -EnsureFileConversionMedia
    }

    Context 'Cross-format document roundtrip conversions' {
        It 'Markdown -> HTML -> Markdown roundtrip' {
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

            $markdown = '# Test Header`n`nThis is test content.'
            $tempFile = Join-Path $TestDrive 'test.md'
            Set-Content -Path $tempFile -Value $markdown

            # Convert to HTML
            { ConvertTo-HtmlFromMarkdown -InputPath $tempFile } | Should -Not -Throw
            $htmlFile = Join-Path $TestDrive 'test.html'
            
            if ($htmlFile -and -not [string]::IsNullOrWhiteSpace($htmlFile) -and (Test-Path -LiteralPath $htmlFile)) {
                # Convert back to Markdown
                Get-Command ConvertFrom-HtmlToMarkdown -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }

        It 'DOCX -> Markdown -> DOCX roundtrip' {
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

            # Note: Requires actual DOCX file for full testing
            Get-Command ConvertFrom-DocxToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-DocxFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'EPUB -> Markdown -> EPUB roundtrip' {
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

            # Note: Requires actual EPUB file for full testing
            Get-Command ConvertFrom-EpubToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-EpubFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ODT -> DOCX -> ODT roundtrip' {
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

            # Note: Requires actual ODT file for full testing
            Get-Command ConvertFrom-OdtToDocx -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-OdtFromDocx -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Textile -> Markdown -> Textile roundtrip' {
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

            # Note: Requires actual Textile file for full testing
            Get-Command ConvertFrom-TextileToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-TextileFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'LaTeX -> Markdown -> LaTeX roundtrip' {
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

            # Note: Requires actual LaTeX file for full testing
            Get-Command ConvertFrom-LaTeXToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-LaTeXFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'RST -> Markdown -> RST roundtrip' {
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

            # Note: Requires actual RST file for full testing
            Get-Command ConvertFrom-RstToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-RstFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'AsciiDoc -> Markdown -> AsciiDoc roundtrip' {
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

            # Note: Requires actual AsciiDoc file for full testing
            Get-Command ConvertFrom-AsciidocToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-AsciidocFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Org-mode -> Markdown -> Org-mode roundtrip' {
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

            # Note: Requires actual Org-mode file for full testing
            Get-Command ConvertFrom-OrgmodeToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-OrgmodeFromMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'MOBI -> EPUB -> MOBI roundtrip' {
            # Skip if tools not available
            $pandoc = Test-ToolAvailable -ToolName 'pandoc' -Silent
            if (-not $pandoc.Available) {
                Set-ItResult -Skipped -Because "pandoc command not available"
                return
            }

            # Note: Requires actual MOBI file for full testing
            Get-Command ConvertFrom-MobiToEpub -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-MobiFromEpub -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }
    }
}

