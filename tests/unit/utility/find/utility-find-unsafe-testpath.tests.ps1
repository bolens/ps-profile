<#
tests/unit/utility-find-unsafe-testpath.tests.ps1

.SYNOPSIS
    Behavioral unit tests for find-unsafe-testpath.ps1 repository scan smoke execution.
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
    $script:FindUnsafeTestPathScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'find-unsafe-testpath.ps1'
    $ConfirmPreference = 'None'
}

Describe 'find-unsafe-testpath.ps1 execution' {
    It 'Scans repository paths and reports heuristic Test-Path findings' {
        $result = Invoke-TestScriptFile -ScriptPath $script:FindUnsafeTestPathScript

        $result.ExitCode | Should -BeIn @(0, $null)
        $result.Output | Should -Match 'unsafe Test-Path|No obviously unsafe Test-Path'
    }

    It 'Detects unsafe Test-Path calls in an isolated repository fixture' {
        $repo = New-TestTempDirectory -Prefix 'FindUnsafeTestPathRepo'
        try {
            $debugDir = Join-Path $repo 'scripts' 'utils' 'debug'
            $testsDir = Join-Path $repo 'tests' 'unit'
            $null = New-Item -ItemType Directory -Path $debugDir -Force
            $null = New-Item -ItemType Directory -Path $testsDir -Force
            Copy-Item -LiteralPath $script:FindUnsafeTestPathScript -Destination (Join-Path $debugDir 'find-unsafe-testpath.ps1') -Force

            Set-Content -LiteralPath (Join-Path $testsDir 'unsafe-fixture.ps1') -Value @'
function Test-UnsafeTestPathFixture {
    param([string]$TargetPath)

    if (Test-Path $TargetPath) {
        return $true
    }

    return $false
}
'@ -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $debugDir 'find-unsafe-testpath.ps1')

            $result.ExitCode | Should -BeIn @(0, $null)
            $result.Output | Should -Match 'potentially unsafe Test-Path|unsafe-fixture\.ps1'
            $result.Output | Should -Match 'TargetPath'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
