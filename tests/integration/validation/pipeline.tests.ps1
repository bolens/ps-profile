<#
tests/integration/validation/pipeline.tests.ps1

.SYNOPSIS
    Integration tests for scripts/checks validation pipeline scripts.
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
            Test-Path -LiteralPath $script:CheckScripts.Idempotency | Should -Be $true -Because 'check-idempotency.ps1 is a required repository check'

            $result = Invoke-ValidationCheck -ScriptPath $script:CheckScripts.Idempotency
            $result.ExitCode | Should -BeIn @(0, 1) -Because 'idempotency check should complete without setup errors'
            $result.Output | Should -Not -Match 'PathResolution module not found'
        }

        It 'check-comment-help.ps1 runs non-interactively' {
            Test-Path -LiteralPath $script:CheckScripts.CommentHelp | Should -Be $true -Because 'check-comment-help.ps1 is a required repository check'

            $result = Invoke-ValidationCheck -ScriptPath $script:CheckScripts.CommentHelp
            $result.ExitCode | Should -BeIn @(0, 1) -Because 'comment-help check should complete without setup errors'
        }

        It 'check-script-standards.ps1 validates scripts directory' {
            Test-Path -LiteralPath $script:CheckScripts.ScriptStandards | Should -Be $true -Because 'check-script-standards.ps1 is a required repository check'

            $scriptsPath = Join-Path $script:RepoRoot 'scripts' 'checks'
            $result = Invoke-ValidationCheck -ScriptPath $script:CheckScripts.ScriptStandards -Arguments @('-Path', $scriptsPath)
            $result.ExitCode | Should -BeIn @(0, 1) -Because 'script standards check should complete without setup errors'
        }

        It 'check-commit-messages.ps1 handles missing remote base gracefully' {
            Test-Path -LiteralPath $script:CheckScripts.CommitMessages | Should -Be $true -Because 'check-commit-messages.ps1 is a required repository check'

            $result = Invoke-ValidationCheck -ScriptPath $script:CheckScripts.CommitMessages -Arguments @('-Base', 'refs/heads/__missing-base-for-tests__')
            $result.ExitCode | Should -BeIn @(0, 1, 2, 3) -Because 'commit message check should exit with a defined code'
        }
    }

    Context 'validate-profile.ps1 orchestration' {
        It 'Defines the expected validation check sequence' {
            Test-Path -LiteralPath $script:CheckScripts.ValidateProfile | Should -Be $true -Because 'validate-profile.ps1 is a required repository check'

            $content = Get-Content -LiteralPath $script:CheckScripts.ValidateProfile -Raw
            foreach ($checkName in @('security scan', 'lint', 'spellcheck', 'markdownlint', 'comment-based help check', 'idempotency', 'duplicate functions')) {
                ($content -match [regex]::Escape($checkName)) | Should -Be $true -Because "validate-profile should orchestrate $checkName"
            }
        }

        It 'Uses Exit-WithCode for validation failures' {
            Test-Path -LiteralPath $script:CheckScripts.ValidateProfile | Should -Be $true -Because 'validate-profile.ps1 is a required repository check'

            $content = Get-Content -LiteralPath $script:CheckScripts.ValidateProfile -Raw
            $content | Should -Match 'Exit-WithCode'
            $content | Should -Not -Match '(?m)^\s*exit\s+\d'
        }
    }
}
