#Requires -Version 7.0
Describe 'Pester CI shard coverage contract' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
        $shardRunner = Join-Path $repoRoot 'scripts/utils/code-quality/run-pester-ci-shard.ps1'
        Import-Module (Join-Path $repoRoot 'scripts/lib/ModuleImport.psm1') -DisableNameChecking
        Import-LibModule -ModuleName 'ExitCodes' -ScriptPath (Join-Path $repoRoot 'scripts') -DisableNameChecking -Global
        $environmentNames = @('PS_PROFILE_NONINTERACTIVE', 'PS_PROFILE_TEST_MODE', 'PS_PROFILE_SUPPRESS_CONFIRMATIONS')
        $savedEnvironment = @{}
        foreach ($name in $environmentNames) {
            $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
        }
        $savedConfirmPreference = $global:ConfirmPreference
        $savedExitCode = Get-Variable LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
        $hadExitCode = $null -ne $savedExitCode
        $savedExitCodeValue = if ($hadExitCode) { $savedExitCode.Value } else { $null }

        $fixtureRoot = Join-Path $TestDrive 'repo'
        $fixtureRunnerDir = Join-Path $fixtureRoot 'scripts/utils/code-quality'
        $null = New-Item -ItemType Directory -Path $fixtureRunnerDir -Force
        # Capture the actual parameter binding at the run-pester boundary.
        @'
param([string]$Suite, [string[]]$Path, [switch]$CI, [switch]$Coverage,
      [switch]$Quiet, [switch]$Parallel, [int]$MaxParallelThreads,
      [string]$TestResultPath)
@{
    CoverageBound = $PSBoundParameters.ContainsKey('Coverage')
    Coverage = [bool]$Coverage
    CI = [bool]$CI
    PathCount = $Path.Count
} | ConvertTo-Json | Set-Content (Join-Path $PSScriptRoot 'parameters.json')
'@ | Set-Content (Join-Path $fixtureRunnerDir 'run-pester.ps1')
    }

    BeforeEach {
        Mock Import-LibModule {}
        Mock Exit-WithCode {}
        $global:LASTEXITCODE = 0
    }

    AfterAll {
        foreach ($name in $environmentNames) {
            [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name])
        }
        $global:ConfirmPreference = $savedConfirmPreference
        if ($hadExitCode) {
            $global:LASTEXITCODE = $savedExitCodeValue
        }
        else {
            Remove-Variable LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'Uses explicit coverage <Expected> for <Shard> with override <Override>' -ForEach @(
        @{ Shard = 'unit-library'; Override = $false; Expected = $false }
        @{ Shard = 'unit-utility'; Override = $false; Expected = $false }
        @{ Shard = 'coverage-smoke'; Override = $false; Expected = $true }
        @{ Shard = 'unit-library'; Override = $true; Expected = $true }
    ) {
        & $shardRunner -RepoRoot $fixtureRoot -Shard $Shard -Coverage:$Override -Quiet
        $bound = Get-Content (Join-Path $fixtureRunnerDir 'parameters.json') -Raw | ConvertFrom-Json
        $bound.CoverageBound | Should -BeTrue
        $bound.Coverage | Should -Be $Expected
        $bound.CI | Should -BeTrue
        $bound.PathCount | Should -BeGreaterThan 0
        Should -Invoke Exit-WithCode -Exactly 1 -ParameterFilter { $ExitCode -eq 0 }
    }
}
