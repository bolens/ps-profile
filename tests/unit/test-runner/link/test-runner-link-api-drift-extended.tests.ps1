<#
tests/unit/test-runner/link/test-runner-link-api-drift-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/link-api-drift.ps1'
}
Describe 'scripts/utils/code-quality/link-api-drift.ps1 extended scenarios' {
    It 'Documents drift linking for generated API docs' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Links generated API docs in docs/api'
        $c | Should -Match 'drift link'
    }
    It 'Supports DryRun Refresh and DocPath parameters' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'DryRun'
        $c | Should -Match 'Refresh'
        $c | Should -Match 'DocPath'
    }
    It 'Parses Defined in source lines relative to docs/' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Defined in:'
        $c | Should -Match 'Resolve-SourcePathFromDoc'
        $c | Should -Match 'docsBase'
    }
    It 'Skips docs/api README index files' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Name -ne 'README.md'"
    }
    It 'Accepts absolute and relative DocPath values' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'IsPathRooted'
    }
    It 'Retries drift link with doc-is-still-accurate after refusal' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'refused: target changed since last link'
        $c | Should -Match '--doc-is-still-accurate'
    }
    It 'Exits non-zero when drift link failures remain' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'exit 1'
        $c | Should -Match '\$failed\.Count -gt 0'
    }
}
