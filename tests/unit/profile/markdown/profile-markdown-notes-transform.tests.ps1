
<#
tests/unit/profile-markdown-notes-transform.tests.ps1

.SYNOPSIS
    Unit tests for note-app markdown content transforms.
#>

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
    $notesModule = Join-Path $script:ProfileDir 'conversion-modules/document/document-markdown-notes.ps1'
    . $notesModule
    if (Get-Command Initialize-FileConversion-DocumentMarkdownNotes -ErrorAction SilentlyContinue) {
        Initialize-FileConversion-DocumentMarkdownNotes
    }
}

Describe 'Markdown note content transforms' {
    Context 'ConvertTo-WikilinksFromMarkdownLinks' {
        It 'Converts relative markdown links to wikilinks' {
            $notePath = 'notes/my-page.md'
            $input = "See [My Page]($notePath) for details."
            $result = ConvertTo-WikilinksFromMarkdownLinks -Content $input
            $result | Should -Be 'See [[notes/my-page|My Page]] for details.'
        }

        It 'Preserves anchor fragments in wikilinks' {
            $input = 'Jump to [Section](doc.md#intro).'
            $result = ConvertTo-WikilinksFromMarkdownLinks -Content $input
            $result | Should -Be 'Jump to [[doc#intro|Section]].'
        }

        It 'Leaves external URLs unchanged' {
            $input = 'Visit [GitHub](https://github.com/example).'
            $result = ConvertTo-WikilinksFromMarkdownLinks -Content $input
            $result | Should -Be $input
        }
    }

    Context 'ConvertTo-MarkdownLinksFromWikilinks' {
        It 'Converts wikilinks with aliases to markdown links' {
            $input = 'See [[my-page|My Page]] for details.'
            $result = ConvertTo-MarkdownLinksFromWikilinks -Content $input
            $result | Should -Be 'See [My Page](my-page) for details.'
        }

        It 'Adds .md extension when requested' {
            $input = 'Link [[other-note]] here.'
            $result = ConvertTo-MarkdownLinksFromWikilinks -Content $input -AddMdExtension
            $result | Should -Be 'Link [other-note](other-note.md) here.'
        }
    }

    Context 'Convert-LogseqPropertiesToYamlFrontMatter' {
        It 'Moves Logseq properties into YAML front matter' {
            $input = @"
title:: My Note
tags:: #work #idea

Body paragraph.
"@
            $result = Convert-LogseqPropertiesToYamlFrontMatter -Content $input
            $result | Should -Match '(?m)^---\s*$'
            $result | Should -Match 'title: My Note'
            $result | Should -Match 'tags:'
            $result | Should -Match 'Body paragraph\.'
        }

        It 'Returns content unchanged when no properties are present' {
            $input = "Plain markdown without properties.`n"
            $result = Convert-LogseqPropertiesToYamlFrontMatter -Content $input
            $result | Should -Be $input
        }
    }

    Context 'Convert-JoplinResourceLinksToLocal' {
        It 'Rewrites Joplin resource IDs using a resource map' {
            $resourceId = '0123456789abcdef0123456789abcdef'
            $input = "Image: ![](:$resourceId)"
            $map = @{ $resourceId = '_resources/photo.png' }
            $result = Convert-JoplinResourceLinksToLocal -Content $input -ResourceMap $map
            $result | Should -Be 'Image: ![](_resources/photo.png)'
        }
    }

    Context 'Convert-NotionCalloutsToObsidian' {
        It 'Converts bold Notion callout labels to Obsidian callouts' {
            $input = "> **Note** This is important."
            $result = Convert-NotionCalloutsToObsidian -Content $input
            $result | Should -Be '> [!NOTE] This is important.'
        }

        It 'Converts emoji-prefixed callouts' {
            $input = '> 💡 Helpful tip here.'
            $result = Convert-NotionCalloutsToObsidian -Content $input
            $result | Should -Be '> [!TIP] Helpful tip here.'
        }
    }

    Context 'Convert-JoplinExportForObsidian' {
        It 'Moves shared resources next to notes that reference them' {
            $exportRoot = New-TestTempDirectory -Prefix 'joplin-export'
            $globalResources = Join-Path $exportRoot '_resources'
            New-Item -ItemType Directory -Path $globalResources -Force | Out-Null

            $noteDir = Join-Path $exportRoot 'Notebook'
            New-Item -ItemType Directory -Path $noteDir -Force | Out-Null

            $attachmentName = '0123456789abcdef0123456789abcdef.png'
            $attachmentPath = Join-Path $globalResources $attachmentName
            Set-Content -LiteralPath $attachmentPath -Value 'png-bytes' -NoNewline

            $notePath = Join-Path $noteDir 'note.md'
            Set-Content -LiteralPath $notePath -Value "Photo: ![](_resources/$attachmentName)" -NoNewline

            $summary = Convert-JoplinExportForObsidian -ExportDirectory $exportRoot
            $summary.MovedResources | Should -BeGreaterThan 0

            $localResource = Join-Path $noteDir '_resources' $attachmentName
            Test-Path -LiteralPath $localResource | Should -BeTrue
        }
    }
}

Describe 'Get-MarkdownDialectPandocFormat' {
    BeforeAll {
        $dialectModule = Join-Path $script:ProfileDir 'conversion-modules/document/document-markdown-dialects.ps1'
        . $dialectModule
    }

    It 'Maps obsidian input dialect to wikilink extensions' {
        $format = Get-MarkdownDialectPandocFormat -Dialect obsidian
        $format | Should -Match 'wikilinks_title_after_pipe'
        $format | Should -Match 'task_lists'
    }

    It 'Maps obsidian output dialect to gfm wikilinks' {
        $format = Get-MarkdownDialectPandocFormat -Dialect obsidian -ForOutput
        $format | Should -Be 'gfm+wikilinks_title_after_pipe'
    }

    It 'Accepts alias github for gfm' {
        Get-MarkdownDialectPandocFormat -Dialect github | Should -Be 'gfm'
    }
}
