<#
tests/unit/utility-run-format.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-format.ps1 dry-run execution.
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
    $script:RunFormatScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'run-format.ps1'
    $ConfirmPreference = 'None'
}

Describe 'run-format.ps1 execution' {
    It 'DryRun executes in-process without modifying isolated files' {
        $formatDir = New-TestTempDirectory -Prefix 'RunFormatInProcessDryRun'
        $sampleFile = Join-Path $formatDir 'sample.ps1'
        $originalContent = "function Get-InProcessDryRunFixture{`r`n'ok'`r`n}"
        [System.IO.File]::WriteAllText($sampleFile, $originalContent)

        $previousDebug = $env:PS_PROFILE_DEBUG
        $env:PS_PROFILE_DEBUG = '3'
        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:RunFormatScript -Path $formatDir -DryRun -Verbose 4>&1
            $outputText = $output | Out-String

            $outputText | Should -Match 'Would format 1 file'
            [System.IO.File]::ReadAllText($sampleFile) | Should -BeExactly $originalContent
        }
        finally {
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'formats files and skips empty files in-process' {
        $formatDir = New-TestTempDirectory -Prefix 'RunFormatInProcessApply'
        $sampleFile = Join-Path $formatDir 'sample.ps1'
        $emptyFile = Join-Path $formatDir 'empty.ps1'
        Set-Content -LiteralPath $sampleFile -Value "function Get-InProcessApplyFixture{ 'ok' }" -Encoding UTF8
        [System.IO.File]::WriteAllText($emptyFile, '')

        $previousDebug = $env:PS_PROFILE_DEBUG
        $env:PS_PROFILE_DEBUG = '2'
        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:RunFormatScript -Path $formatDir 2>&1
            $outputText = $output | Out-String

            $outputText | Should -Match 'Skipping empty file'
            $outputText | Should -Match 'Formatted 1 file'
            [System.IO.File]::ReadAllText($emptyFile) | Should -BeExactly ''
            (Get-Content -LiteralPath $sampleFile -Raw) | Should -Match 'function Get-InProcessApplyFixture'
        }
        finally {
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'reports in-process formatter failures as validation failures' {
        $formatDir = New-TestTempDirectory -Prefix 'RunFormatInProcessFailure'
        Set-Content -LiteralPath (Join-Path $formatDir 'sample.ps1') -Value "'fixture'" -Encoding UTF8
        Mock Invoke-Formatter { throw 'formatter failure probe' }

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            {
                & $script:RunFormatScript -Path $formatDir 2>&1
            } | Should -Throw -ExpectedMessage '*Failed to format 1 file*formatter failure probe*'
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'DryRun previews formatting for an isolated scripts directory' {
        $formatDir = New-TestTempDirectory -Prefix 'RunFormatDryRun'
        Set-Content -LiteralPath (Join-Path $formatDir 'sample.ps1') -Value "function Get-RunFormatFixture { 'ok' }" -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:RunFormatScript -ArgumentList @(
                '-Path', $formatDir,
                '-DryRun'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'DRY RUN|Dry run|Would format'
    }

    It 'Fails parameter validation when the requested path does not exist' {
        $missingPath = Join-Path (New-TestTempDirectory -Prefix 'RunFormatMissingParent') 'does-not-exist'
            $result = Invoke-TestScriptFile -ScriptPath $script:RunFormatScript -ArgumentList @(
                '-Path', $missingPath
            )

            $result.ExitCode | Should -Not -Be 0
            $result.Output | Should -Match 'Path does not exist|does-not-exist'
    }

    It 'Formats an isolated PowerShell file when not in DryRun mode' {
        $formatDir = New-TestTempDirectory -Prefix 'RunFormatApply'
        $sampleFile = Join-Path $formatDir 'sample.ps1'
        Set-Content -LiteralPath $sampleFile -Value "function Get-RunFormatApplyFixture{ 'ok' }" -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:RunFormatScript -ArgumentList @(
                '-Path', $formatDir
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Formatted|Formatting'
            (Get-Content -LiteralPath $sampleFile -Raw) | Should -Match 'function Get-RunFormatApplyFixture'
    }

    It 'Makes every formatting error a validation failure' {
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $script:RunFormatScript,
            [ref]$tokens,
            [ref]$parseErrors
        )
        $errorBranch = @($ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.IfStatementAst] -and
                    $node.Extent.Text -match '\$errors\.Count -gt 0'
                }, $true))[0].Extent.Text

        $errorBranch | Should -Match 'EXIT_VALIDATION_FAILURE'
        $errorBranch | Should -Not -Match 'EXIT_SUCCESS'
    }
}
