<#
tests/unit/utility-init-wrangler-config.tests.ps1

.SYNOPSIS
    Behavioral unit tests for init-wrangler-config.ps1 dry-run execution.
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
    $script:InitWranglerScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'setup' 'init-wrangler-config.ps1'
    $ConfirmPreference = 'None'
}

Describe 'init-wrangler-config.ps1 execution' {
    It 'DryRun previews config creation without prompting for an API token' {
        $result = Invoke-TestScriptFile -ScriptPath $script:InitWranglerScript -ArgumentList @('-DryRun')

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'DRY RUN'
        $result.Output | Should -Not -Match 'Enter Cloudflare API token'
    }

    It 'Creates a Wrangler config file in an isolated XDG config directory' {
        $configHome = New-TestTempDirectory -Prefix 'WranglerConfigHome'
        $expectedFile = Join-Path $configHome '.wrangler' 'config' 'default.toml'
        $result = Invoke-TestScriptFile -ScriptPath $script:InitWranglerScript -ArgumentList @(
    '-ApiToken', 'fixture-token-value',
    '-AccountId', 'fixture-account-id',
    '-Force'
) -EnvironmentVariables @{
    XDG_CONFIG_HOME = $configHome
}

$result.ExitCode | Should -Be 0
$result.Output | Should -Match 'Wrote config to:'
Test-Path -LiteralPath $expectedFile | Should -BeTrue
$content = Get-Content -LiteralPath $expectedFile -Raw
$content | Should -Match 'api_token = "fixture-token-value"'
$content | Should -Match 'account_id = "fixture-account-id"'
    }

    It 'Overwrites an existing config file when Force is specified' {
        $configHome = New-TestTempDirectory -Prefix 'WranglerConfigForce'
        $configDir = Join-Path $configHome '.wrangler' 'config'
        $expectedFile = Join-Path $configDir 'default.toml'
        $null = New-Item -ItemType Directory -Path $configDir -Force
        Set-Content -LiteralPath $expectedFile -Value 'api_token = "old-token"' -Encoding UTF8

        $result = Invoke-TestScriptFile -ScriptPath $script:InitWranglerScript -ArgumentList @(
    '-ApiToken', 'replacement-token',
    '-Force'
) -EnvironmentVariables @{
    XDG_CONFIG_HOME = $configHome
}

$result.ExitCode | Should -Be 0
(Get-Content -LiteralPath $expectedFile -Raw) | Should -Match 'api_token = "replacement-token"'
(Get-Content -LiteralPath $expectedFile -Raw) | Should -Not -Match 'old-token'
    }

    It 'DryRun succeeds without ApiToken and does not write a config file' {
        $configHome = New-TestTempDirectory -Prefix 'WranglerDryRunNoToken'
        $expectedFile = Join-Path $configHome '.wrangler' 'config' 'default.toml'
        $result = Invoke-TestScriptFile -ScriptPath $script:InitWranglerScript -ArgumentList @('-DryRun') -EnvironmentVariables @{
    XDG_CONFIG_HOME = $configHome
}

$result.ExitCode | Should -Be 0
$result.Output | Should -Match 'DRY RUN'
$result.Output | Should -Match 'Would create config file'
Test-Path -LiteralPath $expectedFile | Should -BeFalse
    }
}
