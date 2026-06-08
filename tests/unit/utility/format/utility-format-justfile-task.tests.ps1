<#
tests/unit/utility-format-justfile-task.tests.ps1

.SYNOPSIS
    Unit tests for Format-JustfileTask justfile recipe generation.
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
    $script:TaskGeneratorModule = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'task-parity' 'modules' 'TaskGenerator.psm1'
    Import-Module $script:TaskGeneratorModule -DisableNameChecking -Force
}

AfterAll {
    Remove-Module TaskGenerator -ErrorAction SilentlyContinue -Force
}

Describe 'Format-JustfileTask' {
    It 'Emits variadic ARGS and indented recipe bodies for CLI passthrough commands' {
        $recipe = Format-JustfileTask `
            -TaskName 'generate-changelog' `
            -Command 'pwsh -NoProfile -File scripts/utils/docs/generate-changelog.ps1 {{.CLI_ARGS}}' `
            -Description 'Generate Changelog'

        $recipe | Should -Match '# Generate Changelog'
        $recipe | Should -Match 'generate-changelog \*ARGS:'
        $recipe | Should -Match '    pwsh -NoProfile -File scripts/utils/docs/generate-changelog.ps1 \{\{ ARGS \}\}'
        $recipe | Should -Not -Match 'arguments\(\)'
    }

    It 'Omits ARGS parameter when the command has no CLI passthrough placeholder' {
        $recipe = Format-JustfileTask `
            -TaskName 'lint' `
            -Command 'pwsh -NoProfile -File scripts/utils/code-quality/run-lint.ps1'

        $recipe | Should -Match '(?m)^lint:\s*$'
        $recipe | Should -Not -Match '\*ARGS'
        $recipe | Should -Match '    pwsh -NoProfile -File scripts/utils/code-quality/run-lint.ps1'
    }

    It 'Supports hyphenated task names in generated justfile recipes' {
        $recipe = Format-JustfileTask `
            -TaskName 'quality-check' `
            -Command 'pwsh -NoProfile -File scripts/utils/code-quality/run-lint.ps1' `
            -Description 'Run quality checks'

        $recipe | Should -Match '(?m)^quality-check:\s*$'
        $recipe | Should -Match '# Run quality checks'
    }
}
