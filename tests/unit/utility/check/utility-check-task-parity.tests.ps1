<#
tests/unit/utility-check-task-parity.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-task-parity.ps1 report mode.
#>

function global:Invoke-CheckTaskParityScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:CheckTaskParityScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

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
    $script:CheckTaskParityScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'task-parity' 'check-task-parity.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-task-parity.ps1 execution' {
    It 'Reports task parity for the repository task runner files' {
        $result = Invoke-CheckTaskParityScript -ArgumentList @('-RepoRoot', $script:TestRepoRoot)

        $result.Output | Should -Match 'task|parity|Taskfile|Makefile|package\.json|justfile'
        $result.ExitCode | Should -BeIn @(0, 1)
    }

    It 'WhatIf previews task generation without modifying task runner files' {
        $packageJson = Join-Path $script:TestRepoRoot 'package.json'
        if (-not (Test-Path -LiteralPath $packageJson)) {
            Set-ItResult -Skipped -Because 'package.json is not present'
            return
        }

        $before = Get-Content -LiteralPath $packageJson -Raw
        try {
            $result = Invoke-CheckTaskParityScript -ArgumentList @(
                '-RepoRoot', $script:TestRepoRoot,
                '-Generate',
                '-WhatIf'
            )

            $result.ExitCode | Should -BeIn @(0, 1)
            $result.Output | Should -Match 'What if|WhatIf|parity|task'
            Get-Content -LiteralPath $packageJson -Raw | Should -Be $before
        }
        finally {
            if ((Get-Content -LiteralPath $packageJson -Raw) -ne $before) {
                Set-Content -LiteralPath $packageJson -Value $before -NoNewline -Encoding UTF8
            }
        }
    }

    It 'Fails when the repository root path does not exist' {
        $missingRepo = Join-Path (New-TestTempDirectory -Prefix 'TaskParityMissingRepo') 'missing-repo-root'
            $result = Invoke-CheckTaskParityScript -ArgumentList @('-RepoRoot', $missingRepo)

            $result.ExitCode | Should -Not -Be 0
            $result.Output | Should -Match 'Repository root|not found|missing-repo-root'
    }

    It 'Reports task parity for an isolated repository with minimal runner files' {
        $repo = New-TestTempDirectory -Prefix 'TaskParityIsolated'
            Set-Content -LiteralPath (Join-Path $repo 'package.json') -Value '{"name":"parity-fixture","scripts":{"test":"echo test"}}' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $repo 'Taskfile.yml') -Value "version: '3'`ntasks:`n  test:`n    cmds:`n      - echo test" -Encoding UTF8

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'
                git add package.json Taskfile.yml
                git commit -m 'init task parity fixture' -q
            }
            finally {
                Pop-Location
            }

            $result = Invoke-CheckTaskParityScript -ArgumentList @('-RepoRoot', $repo)
            $result.Output | Should -Match 'task|parity|Taskfile|package\.json'
            $result.ExitCode | Should -BeIn @(0, 1)
    }
}
