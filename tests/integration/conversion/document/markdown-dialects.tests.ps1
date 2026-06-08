

<#
.SYNOPSIS
    Integration tests for markdown dialect conversions.
#>

Describe 'Markdown Dialect Conversion Tests' {
    BeforeAll {
        try {
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
            Initialize-ConversionIntegration -ProfileDir $script:ProfileDir -ModuleType 'Documents' -SelectiveModules @(
                'document-markdown-dialects.ps1'
            ) -EnsureDocuments
        }
        catch {
            throw "Failed to initialize markdown dialect tests: $($_.Exception.Message)"
        }
    }

    Context 'Dialect conversion utilities' {
        It 'Convert-MarkdownDialect function exists' {
            Get-Command Convert-MarkdownDialect -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'ConvertFrom-GfmToCommonmark function exists' {
            Get-Command ConvertFrom-GfmToCommonmark -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'ConvertFrom-ObsidianMarkdownToGfm function exists' {
            Get-Command ConvertFrom-ObsidianMarkdownToGfm -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'ConvertFrom-MediawikiToMarkdown function exists' {
            Get-Command ConvertFrom-MediawikiToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Converts GFM task lists to commonmark when pandoc is available' {
            $pandoc = Test-ToolAvailable -ToolName 'pandoc' -Silent
            if (-not $pandoc.Available) {
                Set-ItResult -Skipped -Because 'pandoc command not available'
                return
            }

            $source = @"
# Tasks

- [ ] Open item
- [x] Done item
"@
            $inputFile = Join-Path $TestDrive 'tasks-gfm.md'
            $outputFile = Join-Path $TestDrive 'tasks-commonmark.md'
            Set-Content -LiteralPath $inputFile -Value $source

            { ConvertFrom-GfmToCommonmark -InputPath $inputFile -OutputPath $outputFile } | Should -Not -Throw
            Test-Path -LiteralPath $outputFile | Should -BeTrue
            (Get-Content -LiteralPath $outputFile -Raw) | Should -Match 'Open item'
        }

        It 'Converts Obsidian wikilinks when pandoc is available' {
            $pandoc = Test-ToolAvailable -ToolName 'pandoc' -Silent
            if (-not $pandoc.Available) {
                Set-ItResult -Skipped -Because 'pandoc command not available'
                return
            }

            $source = @"
# Note

See [[Other Page|details]] and ==highlight== text.
"@
            $inputFile = Join-Path $TestDrive 'obsidian-note.md'
            $outputFile = Join-Path $TestDrive 'obsidian-note-gfm.md'
            Set-Content -LiteralPath $inputFile -Value $source

            { ConvertFrom-ObsidianMarkdownToGfm -InputPath $inputFile -OutputPath $outputFile } | Should -Not -Throw
            Test-Path -LiteralPath $outputFile | Should -BeTrue
            (Get-Content -LiteralPath $outputFile -Raw) | Should -Not -BeNullOrEmpty
        }

        It 'obsidian-to-gfm alias resolves correctly' {
            Get-Alias obsidian-to-gfm -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias obsidian-to-gfm).ResolvedCommandName | Should -Be 'ConvertFrom-ObsidianMarkdownToGfm'
        }
    }
}
