<#
tests/unit/utility-debug-intercept-testpath.tests.ps1

.SYNOPSIS
    Behavioral unit tests for intercept-testpath.ps1 wrapper scenarios.
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
    $script:InterceptTestPathScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'intercept-testpath.ps1'
    $ConfirmPreference = 'None'
}

Describe 'intercept-testpath.ps1 execution' {
    It 'Logs empty LiteralPath arguments after interception is loaded' {
        $probeDir = New-TestTempDirectory -Prefix 'InterceptLiteralPathProbe'
        $probeScript = Join-Path $probeDir 'probe.ps1'
        try {
            $escapedIntercept = $script:InterceptTestPathScript.Replace("'", "''")
            Set-Content -LiteralPath $probeScript -Value @"
. '$escapedIntercept'
Test-Path -LiteralPath ''
"@ -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $probeScript

            $result.Output | Should -Match 'interception enabled|NULL/EMPTY path'
        }
        finally {
            if (Test-Path -LiteralPath $probeDir) {
                Remove-Item -LiteralPath $probeDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Delegates valid paths to the original Test-Path cmdlet' {
        $probeDir = New-TestTempDirectory -Prefix 'InterceptValidPathProbe'
        $probeScript = Join-Path $probeDir 'probe.ps1'
        try {
            $escapedIntercept = $script:InterceptTestPathScript.Replace("'", "''")
            Set-Content -LiteralPath $probeScript -Value @"
. '$escapedIntercept'
if (Test-Path -LiteralPath '$($probeDir.Replace("'", "''"))') { 'ok' } else { 'missing' }
"@ -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $probeScript

            $result.Output | Should -Match 'ok'
            $result.Output | Should -Not -Match 'called with NULL/EMPTY path'
        }
        finally {
            if (Test-Path -LiteralPath $probeDir) {
                Remove-Item -LiteralPath $probeDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
