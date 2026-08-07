<#
tests/unit/utility-run-security-scan.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-security-scan.ps1 against isolated fixtures.
#>

function global:Invoke-SecurityScanScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:SecurityScanScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
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
    $script:SecurityScanScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'security' 'run-security-scan.ps1'
    $script:SecurityFixtureDir = Join-Path $script:TestRepoRoot 'tests' 'test-data' 'security-scan-fixture'
    $script:PssaAvailable = $null -ne (Get-Module -ListAvailable -Name PSScriptAnalyzer)
    $ConfirmPreference = 'None'

    if (-not (Test-Path -LiteralPath $script:SecurityFixtureDir)) {
        New-Item -ItemType Directory -Path $script:SecurityFixtureDir -Force | Out-Null
    }

    Set-Content -LiteralPath (Join-Path $script:SecurityFixtureDir 'insecure.ps1') -Value @'
function Invoke-InsecureFixtureExample {
    Invoke-Expression 'Write-Output insecure-fixture'
}
'@ -Encoding UTF8 -NoNewline
}

Describe 'run-security-scan.ps1 execution' {
    It 'scans an empty directory in-process with portable debug timing' {
        $emptyDir = New-TestTempDirectory -Prefix 'SecurityScanInProcessEmpty'
        $previousDebug = $env:PS_PROFILE_DEBUG
        $env:PS_PROFILE_DEBUG = '3'
        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:SecurityScanScript -Path $emptyDir -Verbose 4>&1
            $outputText = $output | Out-String

            $outputText | Should -Match 'Scanning 0 file'
            $outputText | Should -Match 'no issues found'
        }
        finally {
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'reports warning findings from an isolated fixture in-process' {
        $scanDir = New-TestTempDirectory -Prefix 'SecurityScanInProcessWarning'
        Set-Content -LiteralPath (Join-Path $scanDir 'warning.ps1') -Value @'
function Invoke-SecurityWarningFixture {
    Invoke-Expression 'Write-Output warning-fixture'
}
'@ -Encoding UTF8

        $previousDebug = $env:PS_PROFILE_DEBUG
        $env:PS_PROFILE_DEBUG = '2'
        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:SecurityScanScript -Path $scanDir -Verbose 4>&1
            $outputText = $output | Out-String

            $outputText | Should -Match 'completed with 1 warning'
        }
        finally {
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'loads a custom allowlist during an in-process scan' {
        $workDir = New-TestTempDirectory -Prefix 'SecurityScanInProcessAllowlist'
        $scanDir = Join-Path $workDir 'scan'
        $allowlistPath = Join-Path $workDir 'allowlist.json'
        New-Item -ItemType Directory -Path $scanDir -Force | Out-Null
        @{ FilePatterns = @('fixture\.ps1$') } |
            ConvertTo-Json |
            Set-Content -LiteralPath $allowlistPath -Encoding UTF8

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            $output = & $script:SecurityScanScript -Path $scanDir -AllowlistFile $allowlistPath 2>&1 | Out-String

            $output | Should -Match 'no issues found'
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'fails when an isolated file cannot be scanned in-process' {
        $scanDir = New-TestTempDirectory -Prefix 'SecurityScanInProcessFailure'
        Set-Content -LiteralPath (Join-Path $scanDir 'failure.ps1') -Value "'fixture'" -Encoding UTF8
        Mock Invoke-SecurityScan { throw 'security scan failure probe' }

        $env:PS_PROFILE_TEST_MODE = '1'
        try {
            { & $script:SecurityScanScript -Path $scanDir 2>&1 } |
                Should -Throw -ExpectedMessage '*1 file(s) failed during security scan*'
        }
        finally {
            Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'Completes successfully when the scan directory has no PowerShell files' {
        $emptyDir = New-TestTempDirectory -Prefix 'SecurityScanEmpty'
            $result = Invoke-SecurityScanScript -ArgumentList @('-Path', $emptyDir)
            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'no issues found'
    }

    It 'Fails parameter validation when the scan path does not exist' {
        $missingPath = Join-Path (New-TestTempDirectory -Prefix 'SecurityScanMissing') 'does-not-exist'
        $result = Invoke-SecurityScanScript -ArgumentList @('-Path', $missingPath)
        $result.ExitCode | Should -Be 1
    }

    It 'Reports Invoke-Expression findings for the insecure fixture' {
        if (-not $script:PssaAvailable) {
            Set-ItResult -Skipped -Because 'PSScriptAnalyzer is not installed'
            return
        }

        $result = Invoke-SecurityScanScript -ArgumentList @('-Path', $script:SecurityFixtureDir)
        $result.Output | Should -Match 'PSAvoidUsingInvokeExpression|PSAvoidUsingInvokeExpress|Invoke-Expression'
    }

    It 'Loads a custom allowlist file when AllowlistFile is specified' {
        $workDir = New-TestTempDirectory -Prefix 'SecurityScanAllowlist'
        $allowlistPath = Join-Path $workDir 'allowlist.json'
        $emptyDir = Join-Path $workDir 'scan-target'
        New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
            @{
                FilePatterns = @('insecure\.ps1$')
            } | ConvertTo-Json | Set-Content -LiteralPath $allowlistPath -Encoding UTF8

            $result = Invoke-SecurityScanScript -ArgumentList @(
                '-Path', $emptyDir,
                '-AllowlistFile', $allowlistPath
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'no issues found|Security scan completed'
    }
}
