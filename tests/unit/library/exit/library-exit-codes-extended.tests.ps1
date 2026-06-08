<#
tests/unit/library-exit-codes-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Exit-WithCode test mode and additional exit constants.
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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:ExitCodesPath = Join-Path $script:LibPath 'core' 'ExitCodes.psm1'
    $script:TempDir = New-TestTempDirectory -Prefix 'ExitCodesExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ExitCodes extended scenarios' {
    Context 'Exit-WithCode in test mode' {
        It 'Throws instead of exiting when PS_PROFILE_TEST_MODE is enabled' {
            $testScript = Join-Path $script:TempDir 'exit-test-mode.ps1'
            @"
`$env:PS_PROFILE_TEST_MODE = '1'
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Exit-WithCode -ExitCode 1 -Message 'Test mode failure'
"@ | Set-Content -LiteralPath $testScript -Encoding UTF8

            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Not -Be 0
        }

        It 'Completes successfully in test mode for zero exit codes' {
            $testScript = Join-Path $script:TempDir 'exit-test-mode-success.ps1'
            @"
`$env:PS_PROFILE_TEST_MODE = '1'
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
Write-Output 'completed'
Exit-WithCode -ExitCode 0
"@ | Set-Content -LiteralPath $testScript -Encoding UTF8

            $output = & pwsh -NoProfile -File $testScript 2>&1
            $LASTEXITCODE | Should -Be 0
            ($output | Out-String) | Should -Match 'completed'
        }
    }

    Context 'Additional exit constants' {
        It 'Exports test-runner-specific exit code constants in an isolated process' {
            $testScript = Join-Path $script:TempDir 'exit-constants.ps1'
            @'
Import-Module '{EXIT_CODES}' -DisableNameChecking -Force
Write-Output ('EXIT_TEST_FAILURE=' + $EXIT_TEST_FAILURE)
Write-Output ('EXIT_COVERAGE_FAILURE=' + $EXIT_COVERAGE_FAILURE)
Write-Output ('EXIT_NO_TESTS_FOUND=' + $EXIT_NO_TESTS_FOUND)
Write-Output ('EXIT_TEST_TIMEOUT=' + $EXIT_TEST_TIMEOUT)
'@ -replace '\{EXIT_CODES\}', $script:ExitCodesPath | Set-Content -LiteralPath $testScript -Encoding UTF8

            $output = & pwsh -NoProfile -File $testScript 2>&1 | Out-String

            $output | Should -Match 'EXIT_TEST_FAILURE='
            $output | Should -Match 'EXIT_COVERAGE_FAILURE='
            $output | Should -Match 'EXIT_NO_TESTS_FOUND='
            $output | Should -Match 'EXIT_TEST_TIMEOUT='
        }

        It 'Maps exported constants to ExitCode enum values in an isolated process' {
            $testScript = Join-Path $script:TempDir 'exit-enum-map.ps1'
            @"
Import-Module '$($script:ExitCodesPath)' -DisableNameChecking -Force
if (`$EXIT_TEST_FAILURE -ne [int][ExitCode]::TestFailure) { exit 11 }
if (`$EXIT_WATCH_MODE_CANCELED -ne [int][ExitCode]::WatchModeCanceled) { exit 12 }
exit 0
"@ | Set-Content -LiteralPath $testScript -Encoding UTF8

            & pwsh -NoProfile -File $testScript 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
        }
    }
}
