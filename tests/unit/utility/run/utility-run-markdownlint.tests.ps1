<#
.SYNOPSIS
    Tests markdownlint version selection and exit codes in an isolated PowerShell process.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $null -eq $current.Parent) { break }
        $current = $current.Parent
    }

    $root = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fixture = New-TestTempDirectory -Prefix 'Markdownlint'
    $runnerDir = Join-Path $script:Fixture 'scripts/utils/code-quality'
    $null = New-Item -ItemType Directory -Path $runnerDir, (Join-Path $script:Fixture 'profile.d') -Force
    Copy-Item -LiteralPath (Join-Path $root 'scripts/lib') -Destination (Join-Path $script:Fixture 'scripts/lib') -Recurse
    $script:Runner = Join-Path $runnerDir 'run-markdownlint.ps1'
    Copy-Item -LiteralPath (Join-Path $root 'scripts/utils/code-quality/run-markdownlint.ps1') -Destination $script:Runner
    $script:Manifest = Join-Path $script:Fixture 'package.json'
    $script:Harness = Join-Path $script:Fixture 'invoke-lint.ps1'
    @'
param([string]$Runner, [string]$Version, [int]$LintExitCode)
$env:PS_PROFILE_TEST_MODE = '0'
$env:MARKDOWNLINT_VERSION = $Version

function global:markdownlint { throw 'The ambient markdownlint command must not be used' }
function global:npx {
    param([Parameter(ValueFromRemainingArguments)][object[]]$Arguments)
    Write-Output "npx: $($Arguments -join ' ')"
    $global:LASTEXITCODE = $LintExitCode
}

& $Runner
exit $LASTEXITCODE
'@ | Set-Content -LiteralPath $script:Harness
    $script:PowerShell = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
}

Describe 'run-markdownlint.ps1 execution' {
    BeforeEach {
        '{"devDependencies":{"markdownlint-cli":"0.50.0"}}' | Set-Content -LiteralPath $script:Manifest
    }

    It 'uses the exact repository pin for the npx fallback' {
        $output = & $script:PowerShell -NoProfile -NonInteractive -File $script:Harness -Runner $script:Runner 2>&1 | Out-String
        $LASTEXITCODE | Should -Be 0
        $output | Should -Match 'version: 0\.50\.0'
        $output | Should -Match 'npx: --yes --ignore-scripts markdownlint-cli@0\.50\.0'
        $output | Should -Match 'markdownlint passed'
    }

    It 'uses the checkout launcher only when its version matches the manifest' {
        $modules = Join-Path $script:Fixture 'node_modules'
        $bin = Join-Path $modules '.bin'
        $installed = Join-Path $modules 'markdownlint-cli'
        $null = New-Item -ItemType Directory -Path $bin, $installed -Force
        try {
            if ($IsWindows) {
                @('@echo checkout launcher', '@exit /b 0') | Set-Content -LiteralPath (Join-Path $bin 'markdownlint.cmd') -Encoding ascii
            }
            else {
                $launcher = Join-Path $bin 'markdownlint'
                @('#!/bin/sh', 'echo checkout launcher') | Set-Content -LiteralPath $launcher -Encoding ascii
                chmod +x $launcher
            }
            $installedManifest = Join-Path $installed 'package.json'
            '{"version":"0.50.0"}' | Set-Content -LiteralPath $installedManifest
            $output = & $script:PowerShell -NoProfile -NonInteractive -File $script:Harness -Runner $script:Runner 2>&1 | Out-String
            $LASTEXITCODE | Should -Be 0
            $output | Should -Match 'checkout launcher'
            $output | Should -Not -Match 'npx:'

            '{"version":"0.49.1"}' | Set-Content -LiteralPath $installedManifest
            $output = & $script:PowerShell -NoProfile -NonInteractive -File $script:Harness -Runner $script:Runner 2>&1 | Out-String
            $LASTEXITCODE | Should -Be 0
            $output | Should -Match 'npx: --yes --ignore-scripts markdownlint-cli@0\.50\.0'
        }
        finally {
            Remove-Item -LiteralPath $modules -Recurse -Force
        }
    }

    It 'honors an explicit version without the repository manifest' {
        Remove-Item -LiteralPath $script:Manifest
        $output = & $script:PowerShell -NoProfile -NonInteractive -File $script:Harness -Runner $script:Runner -Version '0.47.0' 2>&1 | Out-String
        $LASTEXITCODE | Should -Be 0
        $output | Should -Match 'npx: --yes --ignore-scripts markdownlint-cli@0\.47\.0'
    }

    It 'rejects <Pin> before invoking the package runner' -ForEach @(
        @{ Pin = 'a range'; ManifestText = '{"devDependencies":{"markdownlint-cli":"^0.50.0"}}' }
        @{ Pin = 'a registry tag'; ManifestText = '{"devDependencies":{"markdownlint-cli":"latest"}}' }
        @{ Pin = 'a missing pin'; ManifestText = '{"devDependencies":{}}' }
    ) {
        Set-Content -LiteralPath $script:Manifest -Value $ManifestText
        $output = & $script:PowerShell -NoProfile -NonInteractive -File $script:Harness -Runner $script:Runner 2>&1 | Out-String
        $LASTEXITCODE | Should -Be 2
        $output | Should -Match 'Cannot prepare markdownlint-cli'
        $output | Should -Not -Match 'npx:'
    }

    It 'reports markdownlint violations with the validation exit code' {
        $output = & $script:PowerShell -NoProfile -NonInteractive -File $script:Harness -Runner $script:Runner -LintExitCode 1 2>&1 | Out-String
        $LASTEXITCODE | Should -Be 1
        $output | Should -Match 'markdownlint found errors'
    }
}
