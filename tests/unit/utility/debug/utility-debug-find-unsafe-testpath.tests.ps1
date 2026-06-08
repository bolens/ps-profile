<#
tests/unit/utility-debug-find-unsafe-testpath.tests.ps1

.SYNOPSIS
    Behavioral unit tests for find-unsafe-testpath.ps1 in an isolated repository layout.
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
    It 'Flags Test-Path calls that use variables without null checks in an isolated layout' {
        $tempRoot = New-TestTempDirectory -Prefix 'unsafe-testpath-scan'
        try {
            $scriptDir = Join-Path $tempRoot 'scripts' 'utils' 'debug'
            $profileDir = Join-Path $tempRoot 'profile.d'
            $null = New-Item -ItemType Directory -Path $scriptDir -Force
            $null = New-Item -ItemType Directory -Path $profileDir -Force

            Copy-Item -LiteralPath $script:FindUnsafeTestPathScript -Destination (Join-Path $scriptDir 'find-unsafe-testpath.ps1')

            Set-Content -LiteralPath (Join-Path $profileDir 'unsafe-fixture.ps1') -Value @'
$configPath = Join-Path $env:HOME '.config'
if (Test-Path $configPath) {
    $configPath
}
'@ -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $scriptDir 'find-unsafe-testpath.ps1')

            $result.Output | Should -Match 'potentially unsafe Test-Path|unsafe-fixture'
            $result.Output | Should -Match 'configPath'
        }
        finally {
            if (Test-Path -LiteralPath $tempRoot) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Reports a clean scan when no unsafe patterns exist in the isolated layout' {
        $tempRoot = New-TestTempDirectory -Prefix 'unsafe-testpath-clean'
        try {
            $scriptDir = Join-Path $tempRoot 'scripts' 'utils' 'debug'
            $profileDir = Join-Path $tempRoot 'profile.d'
            $null = New-Item -ItemType Directory -Path $scriptDir -Force
            $null = New-Item -ItemType Directory -Path $profileDir -Force

            Copy-Item -LiteralPath $script:FindUnsafeTestPathScript -Destination (Join-Path $scriptDir 'find-unsafe-testpath.ps1')

            Set-Content -LiteralPath (Join-Path $profileDir 'safe-fixture.ps1') -Value @'
if ($configPath -and -not [string]::IsNullOrWhiteSpace($configPath) -and (Test-Path -LiteralPath $configPath)) {
    $configPath
}
'@ -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $scriptDir 'find-unsafe-testpath.ps1')

            $result.Output | Should -Match 'No obviously unsafe Test-Path calls found'
        }
        finally {
            if (Test-Path -LiteralPath $tempRoot) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
