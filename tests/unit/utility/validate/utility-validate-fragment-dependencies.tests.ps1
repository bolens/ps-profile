<#
tests/unit/utility-validate-fragment-dependencies.tests.ps1

.SYNOPSIS
    Behavioral unit tests for validate-fragment-dependencies.ps1 smoke execution.
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
    $script:ValidateDepsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'fragment' 'validate-fragment-dependencies.ps1'
    $ConfirmPreference = 'None'
}

Describe 'validate-fragment-dependencies.ps1 execution' {
    It 'Validates fragment dependencies against the repository profile.d directory' {
        $result = Invoke-TestScriptFile -ScriptPath $script:ValidateDepsScript

        $result.ExitCode | Should -BeIn @(0, 1)
        $result.Output | Should -Match 'Validating dependencies|fragment'
    }

    It 'Fails validation when an isolated profile fragment depends on a missing fragment' {
        $repo = New-TestTempDirectory -Prefix 'ValidateFragmentDepsRepo'
        try {
            $fragmentDir = Join-Path $repo 'scripts' 'utils' 'fragment'
            $profileDir = Join-Path $repo 'profile.d'
            $null = New-Item -ItemType Directory -Path $fragmentDir -Force
            $null = New-Item -ItemType Directory -Path $profileDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:ValidateDepsScript -Destination (Join-Path $fragmentDir 'validate-fragment-dependencies.ps1') -Force

            Set-Content -LiteralPath (Join-Path $profileDir 'consumer.ps1') -Value @'
#Requires -Fragment 'missing-fragment-dep'
function Get-ValidateFragmentDepsFixture {
    'consumer'
}
'@ -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $fragmentDir 'validate-fragment-dependencies.ps1')

            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'Dependency validation failed|Missing dependencies'
            $result.Output | Should -Match 'missing-fragment-dep'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
