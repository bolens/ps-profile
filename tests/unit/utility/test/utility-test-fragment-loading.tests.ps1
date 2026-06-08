<#
tests/unit/utility-test-fragment-loading.tests.ps1

.SYNOPSIS
    Behavioral smoke test for test-fragment-loading.ps1.
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
    $script:TestFragmentLoadingScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'fragment' 'test-fragment-loading.ps1'
    $ConfirmPreference = 'None'
}

Describe 'test-fragment-loading.ps1 execution' {
    It 'Loads profile fragments and reports a summary' {
        if ($env:CI -or $env:GITHUB_ACTIONS) {
            Set-ItResult -Skipped -Because 'full fragment loading is too slow for CI'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:TestFragmentLoadingScript

        $result.ExitCode | Should -BeIn @(0, 1)
        $result.Output | Should -Match 'Testing fragment loading|Test Summary|fragments'
    }

    It 'Loads fragments from an isolated profile.d directory' {
        $repo = New-TestTempDirectory -Prefix 'TestFragmentLoadingRepo'
        try {
            $profileDir = Join-Path $repo 'profile.d'
            $fragmentDir = Join-Path $repo 'scripts' 'utils' 'fragment'
            $null = New-Item -ItemType Directory -Path $profileDir -Force
            $null = New-Item -ItemType Directory -Path $fragmentDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:TestFragmentLoadingScript -Destination (Join-Path $fragmentDir 'test-fragment-loading.ps1') -Force
            Set-Content -LiteralPath (Join-Path $profileDir 'fixture.ps1') -Value @'
if (-not (Test-Path Function:\Test-FragmentLoadingFixture)) {
    function Test-FragmentLoadingFixture { 'ok' }
}
'@ -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $fragmentDir 'test-fragment-loading.ps1')

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Testing fragment loading for 1 fragments'
            $result.Output | Should -Match 'Test Summary|Successful'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
