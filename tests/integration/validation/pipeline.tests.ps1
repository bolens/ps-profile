<#
tests/integration/validation/pipeline.tests.ps1

.SYNOPSIS
    Integration tests for scripts/checks validation pipeline scripts.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ChecksDir = Get-TestPath -RelativePath 'scripts\checks' -StartPath $PSScriptRoot -EnsureExists
    $script:PsExe = (Get-Command pwsh -ErrorAction Stop).Source

    $script:CheckScripts = @{
        ValidateProfile   = Join-Path $script:ChecksDir 'validate-profile.ps1'
        Idempotency       = Join-Path $script:ChecksDir 'check-idempotency.ps1'
        CommentHelp       = Join-Path $script:ChecksDir 'check-comment-help.ps1'
        ScriptStandards   = Join-Path $script:ChecksDir 'check-script-standards.ps1'
        CommitMessages    = Join-Path $script:ChecksDir 'check-commit-messages.ps1'
    }
}

function script:Invoke-ValidationCheck {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [string[]]$Arguments = @()
    )

    $argList = @('-NoProfile', '-File', $ScriptPath) + $Arguments
    $output = & $script:PsExe @argList 2>&1
    return [PSCustomObject]@{
        ExitCode = $LASTEXITCODE
        Output   = ($output -join [Environment]::NewLine)
    }
}

Describe 'Validation pipeline integration' {
    Context 'Individual check scripts' {
        It 'check-idempotency.ps1 runs non-interactively against profile.d' {
            if (-not (Test-Path -LiteralPath $script:CheckScripts.Idempotency)) {
                Set-ItResult -Skipped -Because 'check-idempotency.ps1 not found'
                return
            }

            $result = Invoke-ValidationCheck -ScriptPath $script:CheckScripts.Idempotency
            $result.ExitCode | Should -BeIn @(0, 1) -Because 'idempotency check should complete without setup errors'
            $result.Output | Should -Not -Match 'PathResolution module not found'
        }

        It 'check-comment-help.ps1 runs non-interactively' {
            if (-not (Test-Path -LiteralPath $script:CheckScripts.CommentHelp)) {
                Set-ItResult -Skipped -Because 'check-comment-help.ps1 not found'
                return
            }

            $result = Invoke-ValidationCheck -ScriptPath $script:CheckScripts.CommentHelp
            $result.ExitCode | Should -BeIn @(0, 1) -Because 'comment-help check should complete without setup errors'
        }

        It 'check-script-standards.ps1 validates scripts directory' {
            if (-not (Test-Path -LiteralPath $script:CheckScripts.ScriptStandards)) {
                Set-ItResult -Skipped -Because 'check-script-standards.ps1 not found'
                return
            }

            $scriptsPath = Join-Path $script:RepoRoot 'scripts' 'checks'
            $result = Invoke-ValidationCheck -ScriptPath $script:CheckScripts.ScriptStandards -Arguments @('-Path', $scriptsPath)
            $result.ExitCode | Should -BeIn @(0, 1) -Because 'script standards check should complete without setup errors'
        }

        It 'check-commit-messages.ps1 handles missing remote base gracefully' {
            if (-not (Test-Path -LiteralPath $script:CheckScripts.CommitMessages)) {
                Set-ItResult -Skipped -Because 'check-commit-messages.ps1 not found'
                return
            }

            $result = Invoke-ValidationCheck -ScriptPath $script:CheckScripts.CommitMessages -Arguments @('-Base', 'refs/heads/__missing-base-for-tests__')
            $result.ExitCode | Should -BeIn @(0, 1, 2, 3) -Because 'commit message check should exit with a defined code'
        }
    }

    Context 'validate-profile.ps1 orchestration' {
        It 'Defines the expected validation check sequence' {
            if (-not (Test-Path -LiteralPath $script:CheckScripts.ValidateProfile)) {
                Set-ItResult -Skipped -Because 'validate-profile.ps1 not found'
                return
            }

            $content = Get-Content -LiteralPath $script:CheckScripts.ValidateProfile -Raw
            foreach ($checkName in @('security scan', 'lint', 'spellcheck', 'comment-based help check', 'idempotency', 'duplicate functions')) {
                ($content -match [regex]::Escape($checkName)) | Should -Be $true -Because "validate-profile should orchestrate $checkName"
            }
        }

        It 'Uses Exit-WithCode for validation failures' {
            if (-not (Test-Path -LiteralPath $script:CheckScripts.ValidateProfile)) {
                Set-ItResult -Skipped -Because 'validate-profile.ps1 not found'
                return
            }

            $content = Get-Content -LiteralPath $script:CheckScripts.ValidateProfile -Raw
            $content | Should -Match 'Exit-WithCode'
            $content | Should -Not -Match '(?m)^\s*exit\s+\d'
        }
    }
}
