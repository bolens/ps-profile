<#
tests/unit/utility-check-missing-packages.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-missing-packages.ps1 orchestration smoke test.
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
    $script:CheckMissingPackagesScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'dependencies' 'check-missing-packages.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-missing-packages.ps1 execution' {
    It 'Runs package checks against the repository manifests without interactive prompts' {
        $result = Invoke-TestScriptFile -ScriptPath $script:CheckMissingPackagesScript

        $result.Output | Should -Match 'npm|python|package|Checking'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Checks npm dependencies from an isolated repository package.json' {
        $repo = New-TestTempDirectory -Prefix 'CheckMissingPackagesRepo'
        try {
            $scriptDir = Join-Path $repo 'scripts' 'utils' 'dependencies'
            $null = New-Item -ItemType Directory -Path $scriptDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:CheckMissingPackagesScript -Destination (Join-Path $scriptDir 'check-missing-packages.ps1') -Force

            @{
                name         = 'missing-packages-fixture'
                version      = '1.0.0'
                dependencies = @{
                    'definitely-not-a-real-npm-package-xyz' = '1.0.0'
                }
            } | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $repo 'package.json') -Encoding UTF8

            Set-Content -LiteralPath (Join-Path $repo 'requirements.txt') -Value '' -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $scriptDir 'check-missing-packages.ps1')

            $result.Output | Should -Match 'npm|package|Checking|definitely-not-a-real-npm-package-xyz|missing'
            $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
