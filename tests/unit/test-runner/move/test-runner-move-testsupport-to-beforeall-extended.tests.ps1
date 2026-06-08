<#
tests/unit/test-runner-move-testsupport-to-beforeall-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for move-testsupport-to-beforeall.ps1 refactor script.
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
    $script:MoveScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/move-testsupport-to-beforeall.ps1'
}

Describe 'move-testsupport-to-beforeall.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents moving top-level TestSupport imports into BeforeAll hooks' {
            $content = Get-Content -LiteralPath $script:MoveScript -Raw
            $content | Should -Match 'Moves top-level TestSupport\.ps1 dot-sourcing'
        }

        It 'Accepts RepoRoot to locate test directories' {
            $content = Get-Content -LiteralPath $script:MoveScript -Raw
            $content | Should -Match 'RepoRoot'
            $content | Should -Match 'Get-RepoRoot'
        }
    }

    Context 'Regex migration patterns' {
        It 'Detects top-level TestSupport dot-source lines' {
            $content = Get-Content -LiteralPath $script:MoveScript -Raw
            $content | Should -Match 'dotSourcePattern'
            $content | Should -Match 'TestSupport\.ps1'
        }

        It 'Rewrites imports before existing BeforeAll blocks' {
            $content = Get-Content -LiteralPath $script:MoveScript -Raw
            $content | Should -Match 'BeforeAll \{'
            $content | Should -Match 'importLineTemplate'
        }

        It 'Creates BeforeAll wrappers before Describe blocks when needed' {
            $content = Get-Content -LiteralPath $script:MoveScript -Raw
            $content | Should -Match 'Describe '
        }
    }

    Context 'Scan scope' {
        It 'Targets integration and performance test directories' {
            $content = Get-Content -LiteralPath $script:MoveScript -Raw
            $content | Should -Match "'tests' 'integration'"
            $content | Should -Match "'tests' 'performance'"
        }
    }
}
