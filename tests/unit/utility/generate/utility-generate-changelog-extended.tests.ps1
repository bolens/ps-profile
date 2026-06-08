<#
tests/unit/utility-generate-changelog-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for generate-changelog.ps1 git-cliff wrapper.
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ChangelogScript = Join-Path $script:TestRepoRoot 'scripts/utils/docs/generate-changelog.ps1'
}

Describe 'generate-changelog.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents OutputFile and Unreleased parameters' {
            $content = Get-Content -LiteralPath $script:ChangelogScript -Raw
            $content | Should -Match '\.PARAMETER OutputFile'
            $content | Should -Match '\.PARAMETER Unreleased'
        }

        It 'Uses git-cliff with conventional commit history' {
            $content = Get-Content -LiteralPath $script:ChangelogScript -Raw
            $content | Should -Match 'git-cliff'
            $content | Should -Match 'cliff\.toml'
        }
    }

    Context 'Tool availability' {
        It 'Attempts cargo-based installation when git-cliff is missing' {
            $content = Get-Content -LiteralPath $script:ChangelogScript -Raw
            $content | Should -Match 'cargo'
            $content | Should -Match 'git-cliff'
        }
    }

    Context 'Output defaults' {
        It 'Defaults changelog output to CHANGELOG.md' {
            $content = Get-Content -LiteralPath $script:ChangelogScript -Raw
            $content | Should -Match 'CHANGELOG\.md'
        }
    }
}
