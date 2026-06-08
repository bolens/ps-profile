<#
tests/unit/utility-intercept-testpath.tests.ps1

.SYNOPSIS
    Behavioral unit tests for intercept-testpath.ps1 wrapper behavior.
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
    It 'Logs null Test-Path calls after the interception wrapper is loaded' {
        $probeScript = Join-Path (New-TestTempDirectory -Prefix 'InterceptTestPathProbe') 'probe.ps1'
        try {
            Set-Content -LiteralPath $probeScript -Value @"
. '$($script:InterceptTestPathScript)'
`$null | Out-Null
Test-Path ''
"@ -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $probeScript

            $result.Output | Should -Match 'interception enabled|NULL/EMPTY path'
        }
        finally {
            $parent = Split-Path -Parent $probeScript
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Logs null LiteralPath Test-Path calls after the interception wrapper is loaded' {
        $probeScript = Join-Path (New-TestTempDirectory -Prefix 'InterceptLiteralPathProbe') 'probe.ps1'
        try {
            Set-Content -LiteralPath $probeScript -Value @"
. '$($script:InterceptTestPathScript)'
Test-Path -LiteralPath ''
"@ -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $probeScript

            $result.Output | Should -Match 'interception enabled|NULL/EMPTY path|LiteralPath'
        }
        finally {
            $parent = Split-Path -Parent $probeScript
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
