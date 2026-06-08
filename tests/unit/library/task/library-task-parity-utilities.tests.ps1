<#
tests/unit/library-task-parity-utilities.tests.ps1

.SYNOPSIS
    Unit tests for TaskParityUtilities module.
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
    $repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..' '..')).Path
    $script:ModulePath = Join-Path $repoRoot 'scripts' 'utils' 'task-parity' 'modules' 'TaskParityUtilities.psm1'
    Import-Module $script:ModulePath -DisableNameChecking -Force
}

AfterAll {
    Remove-Module TaskParityUtilities -ErrorAction SilentlyContinue -Force
}

Describe 'TaskParityUtilities' {
    It 'Get-TextLineEnding detects CRLF and LF' {
        Get-TextLineEnding -Content "a`r`nb" | Should -Be "`r`n"
        Get-TextLineEnding -Content "a`nb" | Should -Be "`n"
    }

    It 'Split-TaskCommandLines handles CRLF multiline commands' {
        $lines = Split-TaskCommandLines -Command "pwsh -NoProfile`r`npwsh -File scripts/utils/test.ps1"
        $lines.Count | Should -Be 2
    }

    It 'Normalize-TaskScriptPathInText converts backslashes under scripts/' {
        $input = 'pwsh -NoProfile -File scripts\utils\code-quality\run-lint.ps1'
        Normalize-TaskScriptPathInText -Text $input | Should -Be 'pwsh -NoProfile -File scripts/utils/code-quality/run-lint.ps1'
    }

    It 'ConvertFrom-PwshInvocationCommand uses forward-slash workspace paths' {
        $result = ConvertFrom-PwshInvocationCommand -Command 'pwsh -NoProfile -File scripts/utils/docs/generate-docs.ps1 -WhatIf'
        $result.Command | Should -Be 'pwsh'
        $result.Args | Should -Contain '-File'
        $result.Args | Should -Contain '${workspaceFolder}/scripts/utils/docs/generate-docs.ps1'
        $result.Args | Should -Contain '-WhatIf'
    }

    It 'ConvertTo-VsCodeShellTaskDefinition parses drift and pnpm commands' {
        $drift = ConvertTo-VsCodeShellTaskDefinition -Label 'drift-check' -Command 'drift check'
        $drift.command | Should -Be 'drift'
        $drift.args | Should -Be @('check')

        $pnpm = ConvertTo-VsCodeShellTaskDefinition -Label 'install-all' -Command 'pnpm run install-all'
        $pnpm.command | Should -Be 'pnpm'
        $pnpm.args[0] | Should -Be 'run'
    }

    It 'Write-TaskParityTextFile preserves CRLF when updating existing files' {
        $tempDir = New-TestTempDirectory -Prefix 'TaskParityUtilities'
        $filePath = Join-Path $tempDir 'sample.txt'
        $crlfContent = "line1`r`nline2`r`n"
        [System.IO.File]::WriteAllText($filePath, $crlfContent, [System.Text.UTF8Encoding]::new($false))

        Write-TaskParityTextFile -Path $filePath -Content 'line1' -ExistingContent $crlfContent
        $written = [System.IO.File]::ReadAllText($filePath)
        $written | Should -Match "`r`n"
    }

    It 'Join-TaskCommandLines normalizes script paths' {
        Join-TaskCommandLines -Lines @(
            'pwsh -NoProfile -File scripts\utils\test.ps1'
        ) | Should -Be 'pwsh -NoProfile -File scripts/utils/test.ps1'
    }
}
