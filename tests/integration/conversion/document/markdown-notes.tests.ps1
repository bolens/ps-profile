

<#
.SYNOPSIS
    Integration tests for note-app markdown migration tools.
#>

Describe 'Markdown Notes Migration Tests' {
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
        Initialize-ConversionIntegration -ProfileDir $script:ProfileDir -ModuleType 'Documents' -SelectiveModules @(
            'document-markdown-notes.ps1'
        ) -EnsureDocuments
    }
    catch {
        throw "Failed to initialize markdown notes tests: $($_.Exception.Message)"
    }

    Context 'Migration CLI wrappers' {
        It 'Export-NotionPageToMarkdown function exists' {
            Get-Command Export-NotionPageToMarkdown -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Sync-JoplinObsidianNotes function exists' {
            Get-Command Sync-JoplinObsidianNotes -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Invoke-NotionifyCli function exists' {
            Get-Command Invoke-NotionifyCli -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Export-NotionPageToMarkdown warns when no CLI is available' {
            Set-TestCommandAvailabilityState -CommandName 'notion2md' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'notionify-cli' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'notion2markdown' -Available $false

            { Export-NotionPageToMarkdown -Url 'https://notion.so/test' -ErrorAction Stop } | Should -Throw
        }

        It 'Sync-JoplinObsidianNotes warns when job CLI is unavailable' {
            Set-TestCommandAvailabilityState -CommandName 'job' -Available $false

            { Sync-JoplinObsidianNotes -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'Aliases' {
        It 'notion-to-markdown alias resolves correctly' {
            Get-Alias notion-to-markdown -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias notion-to-markdown).ResolvedCommandName | Should -Be 'Export-NotionPageToMarkdown'
        }

        It 'joplin-obsidian-sync alias resolves correctly' {
            Get-Alias joplin-obsidian-sync -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias joplin-obsidian-sync).ResolvedCommandName | Should -Be 'Sync-JoplinObsidianNotes'
        }

        It 'md-links-to-wikilinks alias resolves correctly' {
            Get-Alias md-links-to-wikilinks -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias md-links-to-wikilinks).ResolvedCommandName | Should -Be 'ConvertTo-WikilinksFromMarkdownLinks'
        }
    }
}
