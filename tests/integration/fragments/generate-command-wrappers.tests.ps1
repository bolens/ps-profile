<#
tests/integration/fragments/generate-command-wrappers.tests.ps1

.SYNOPSIS
    Integration tests for generate-command-wrappers.ps1 script behavior.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:WrapperScript = Join-Path $script:RepoRoot 'scripts' 'utils' 'fragment' 'generate-command-wrappers.ps1'
    $script:RegistryModulePath = Join-Path $script:RepoRoot 'scripts' 'lib' 'fragment' 'FragmentCommandRegistry.psm1'
    $script:PsExe = (Get-Command pwsh -ErrorAction Stop).Source
}

Describe 'generate-command-wrappers integration' {
    Context 'Script prerequisites' {
        It 'Exists and has comment-based help' {
            Test-Path -LiteralPath $script:WrapperScript | Should -Be $true
            $help = Get-Help $script:WrapperScript -ErrorAction SilentlyContinue
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It 'Documents DryRun and Force switches' {
            $content = Get-Content -LiteralPath $script:WrapperScript -Raw
            $content | Should -Match '\.PARAMETER DryRun'
            $content | Should -Match '\.PARAMETER Force'
        }
    }

    Context 'Execution behavior' {
        It 'Runs DryRun when FragmentCommandRegistry module is available' {
            if (-not (Test-Path -LiteralPath $script:RegistryModulePath)) {
                Set-ItResult -Skipped -Because 'FragmentCommandRegistry module is not available'
                return
            }

            $tempOutput = New-TestTempDirectory -Prefix 'CommandWrappers'
            try {
                $dryRunCommand = @"
Import-Module '$($script:RegistryModulePath)' -DisableNameChecking -ErrorAction Stop
Register-FragmentCommand -CommandName 'Test-WrapperCmd' -FragmentName 'bootstrap' -CommandType 'Function' | Out-Null
& '$($script:WrapperScript)' -DryRun -OutputPath '$tempOutput'
exit `$LASTEXITCODE
"@
                $output = & $script:PsExe -NoProfile -Command $dryRunCommand 2>&1
                $LASTEXITCODE | Should -Be 0
                @(Get-ChildItem -LiteralPath $tempOutput -File -ErrorAction SilentlyContinue).Count | Should -Be 0
                ($output -join ' ') | Should -Match 'GENERATE|Found .* command' -Because 'DryRun should report planned wrapper generation'
            }
            finally {
                if ($tempOutput -and (Test-Path -LiteralPath $tempOutput)) {
                    Remove-Item -LiteralPath $tempOutput -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
