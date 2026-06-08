<#
tests/unit/utility-trace-testpath.tests.ps1

.SYNOPSIS
    Behavioral unit tests for trace-testpath.ps1 with a narrow test file target.
#>

function global:New-TraceTestPathRepository {
    $repo = New-TestTempDirectory -Prefix 'TraceTestPathRepo'
    $debugDir = Join-Path $repo 'scripts' 'utils' 'debug'
    $runnerDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
    $testsDir = Join-Path $repo 'tests' 'unit'
    $null = New-Item -ItemType Directory -Path $debugDir -Force
    $null = New-Item -ItemType Directory -Path $runnerDir -Force
    $null = New-Item -ItemType Directory -Path $testsDir -Force

    $libSource = Join-Path $script:TestRepoRoot 'scripts' 'lib'
    if (Test-Path -LiteralPath $libSource) {
        Copy-Item -LiteralPath $libSource -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
    }

    Copy-Item -LiteralPath $script:TraceTestPathScript -Destination (Join-Path $debugDir 'trace-testpath.ps1') -Force
    Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value @'
param(
    [string]$Suite,
    [string]$Path
)

Write-Output "TRACE_RUNNER_STUB Suite=$Suite Path=$Path"
exit 0
'@ -Encoding UTF8

    $fixtureTestFile = Join-Path $testsDir 'trace-fixture.tests.ps1'
    Set-Content -LiteralPath $fixtureTestFile -Value @'
Describe 'trace fixture' {
    It 'passes' {
        $true | Should -BeTrue
    }
}
'@ -Encoding UTF8

    return @{
        Repo            = $repo
        TraceScriptPath = Join-Path $debugDir 'trace-testpath.ps1'
        FixtureTestFile = $fixtureTestFile
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
    $script:TraceTestPathScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'trace-testpath.ps1'
    $ConfirmPreference = 'None'
}

Describe 'trace-testpath.ps1 execution' {
    It 'Invokes the test runner with tracing enabled in an isolated repository' {
        $fixture = New-TraceTestPathRepository
        try {
            $result = Invoke-TestScriptFile -ScriptPath $fixture.TraceScriptPath -ArgumentList @(
                '-TestFile', $fixture.FixtureTestFile
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Test-Path Tracing Enabled'
            $result.Output | Should -Match 'TRACE_RUNNER_STUB'
            $result.Output | Should -Match 'trace-fixture\.tests\.ps1'
        }
        finally {
            if (Test-Path -LiteralPath $fixture.Repo) {
                Remove-Item -LiteralPath $fixture.Repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails parameter validation when TestFile is not provided' {
        $output = & pwsh -NoProfile -File $script:TraceTestPathScript 2>&1 | Out-String

        $LASTEXITCODE | Should -Not -Be 0
        $output | Should -Match 'TestFile|MissingArgument|mandatory'
    }
}
