<#
tests/unit/validation-validate-profile-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for validate-profile.ps1 orchestration script.
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
    $script:ValidateScript = Join-Path $script:TestRepoRoot 'scripts/checks/validate-profile.ps1'
}

Describe 'validate-profile.ps1 extended scenarios' {
    Context 'Validation pipeline' {
        It 'Runs security lint spellcheck comment-help and idempotency checks' {
            $content = Get-Content -LiteralPath $script:ValidateScript -Raw
            $content | Should -Match 'security scan'
            $content | Should -Match "'lint'"
            $content | Should -Match 'spellcheck'
            $content | Should -Match 'comment-based help check'
            $content | Should -Match 'idempotency'
        }

        It 'Includes duplicate function detection in the pipeline' {
            $content = Get-Content -LiteralPath $script:ValidateScript -Raw
            $content | Should -Match 'duplicate functions'
            $content | Should -Match 'find-duplicate-functions\.ps1'
        }
    }

    Context 'Child process execution' {
        It 'Invokes each validation script via Get-PowerShellExecutable' {
            $content = Get-Content -LiteralPath $script:ValidateScript -Raw
            $content | Should -Match 'Get-PowerShellExecutable'
            $content | Should -Match '-NoProfile'
            $content | Should -Match '-File'
        }

        It 'Stops the pipeline on the first failing check' {
            $content = Get-Content -LiteralPath $script:ValidateScript -Raw
            $content | Should -Match 'LASTEXITCODE'
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
        }
    }

    Context 'Script resolution' {
        It 'Resolves utility scripts under scripts/utils/code-quality and security' {
            $content = Get-Content -LiteralPath $script:ValidateScript -Raw
            $content | Should -Match "'code-quality'"
            $content | Should -Match "'security'"
            $content | Should -Match 'run-lint\.ps1'
            $content | Should -Match 'run-security-scan\.ps1'
        }
    }
}
