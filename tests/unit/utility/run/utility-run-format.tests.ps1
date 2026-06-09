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
}
