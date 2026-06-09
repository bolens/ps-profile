<#
tests/unit/utility-repro-set-agentmode.tests.ps1

.SYNOPSIS
    Behavioral smoke test for repro_set_agentmode.ps1 bootstrap idempotency checks.
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
    $script:ReproSetAgentModeScript = Join-Path $script:TestRepoRoot 'scripts' 'repro_set_agentmode.ps1'
    $ConfirmPreference = 'None'
}

Describe 'repro_set_agentmode.ps1 execution' {
    It 'Sources bootstrap helpers and verifies Set-AgentModeFunction idempotency' {
        $result = Invoke-TestScriptFile -ScriptPath $script:ReproSetAgentModeScript

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'repro_set_agentmode: PASSED'
    }

    It 'Fails when bootstrap.ps1 is missing in an isolated repository' {
        $repo = New-TestTempDirectory -Prefix 'ReproMissingBootstrap'
        $scriptsDir = Join-Path $repo 'scripts'
        $null = New-Item -ItemType Directory -Path $scriptsDir -Force
        Copy-Item -LiteralPath $script:ReproSetAgentModeScript -Destination (Join-Path $scriptsDir 'repro_set_agentmode.ps1') -Force
                $result = Invoke-TestScriptFile -ScriptPath (Join-Path $scriptsDir 'repro_set_agentmode.ps1')
                $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'Bootstrap file not found'
    }

    It 'Passes when bootstrap.ps1 is present in an isolated repository' {
        $repo = New-TestTempDirectory -Prefix 'ReproBootstrapPass'
        $scriptsDir = Join-Path $repo 'scripts'
        $profileDir = Join-Path $repo 'profile.d'
        $null = New-Item -ItemType Directory -Path $scriptsDir -Force
        $null = New-Item -ItemType Directory -Path $profileDir -Force
        Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'profile.d' 'bootstrap.ps1') -Destination (Join-Path $profileDir 'bootstrap.ps1') -Force
        Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'profile.d' 'bootstrap') -Destination (Join-Path $profileDir 'bootstrap') -Recurse -Force
        Copy-Item -LiteralPath $script:ReproSetAgentModeScript -Destination (Join-Path $scriptsDir 'repro_set_agentmode.ps1') -Force
                Push-Location $repo
        try {
            git init -q | Out-Null
            git config user.email 'fixture@example.com'
            git config user.name 'Fixture'
                    $result = Invoke-TestScriptFile -ScriptPath (Join-Path $scriptsDir 'repro_set_agentmode.ps1')
        }
        finally {
            Pop-Location
        }
                $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'repro_set_agentmode: PASSED'
    }
}
