<#
tests/unit/test-runner-validation-reporter.tests.ps1

.SYNOPSIS
    Unit tests for ValidationReporter and FunctionDiscovery modules.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'ValidationReporter.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'FunctionDiscovery.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'ValidationReporterTests'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ValidationReporter Module' {
    Context 'Get-ValidationResults' {
        It 'Counts approved and unapproved functions' {
            $functions = @(
                [pscustomobject]@{
                    Name                     = 'Get-ValidSample'
                    Verb                     = 'Get'
                    Noun                     = 'ValidSample'
                    IsValidFormat            = $true
                    HasApprovedVerb          = $true
                    FilePath                 = '/tmp/validation-reporter/valid.ps1'
                    RelativePath             = 'valid.ps1'
                    UsesSetAgentModeFunction = $false
                },
                [pscustomobject]@{
                    Name                     = 'BadVerb-Sample'
                    Verb                     = 'BadVerb'
                    Noun                     = 'Sample'
                    IsValidFormat            = $true
                    HasApprovedVerb          = $false
                    FilePath                 = '/tmp/validation-reporter/bad.ps1'
                    RelativePath             = 'bad.ps1'
                    UsesSetAgentModeFunction = $false
                },
                [pscustomobject]@{
                    Name                     = 'NotValidFormat'
                    Verb                     = 'NotValidFormat'
                    Noun                     = $null
                    IsValidFormat            = $false
                    HasApprovedVerb          = $false
                    FilePath                 = '/tmp/validation-reporter/invalid.ps1'
                    RelativePath             = 'invalid.ps1'
                    UsesSetAgentModeFunction = $false
                }
            )

            $results = Get-ValidationResults -Functions $functions -Exceptions @{} -ExceptionVerbs @('_none_')

            $results.TotalFunctions | Should -Be 3
            $results.FunctionsWithApprovedVerbs | Should -Be 1
            $results.FunctionsWithUnapprovedVerbs | Should -Be 1
            $results.FunctionsWithInvalidFormat | Should -Be 1
            $results.Issues.Count | Should -Be 2
        }
    }

    Context 'Save-ValidationReport' {
        It 'Writes JSON report to disk' {
            $results = [pscustomobject]@{
                TotalFunctions                     = 1
                FunctionsWithApprovedVerbs         = 1
                FunctionsWithUnapprovedVerbs       = 0
                FunctionsWithInvalidFormat         = 0
                ProfileDFunctionsNotUsingAgentMode = 0
                ExceptionsCount                    = 0
                Functions                          = @()
                Issues                             = @()
            }

            $outputPath = Join-Path $script:TempDir 'validation-report.json'
            Save-ValidationReport -Results $results -OutputPath $outputPath

            Test-Path -LiteralPath $outputPath | Should -Be $true
            $saved = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
            $saved.Summary.TotalFunctions | Should -Be 1
            $saved.Timestamp | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'FunctionDiscovery Module' {
    Context 'Get-FunctionsFromPath' {
        It 'Discovers standard and agent-mode functions' {
            $scanDir = Join-Path $script:TempDir 'scan'
            New-Item -ItemType Directory -Path $scanDir -Force | Out-Null

            $file = Join-Path $scanDir 'sample.ps1'
            Set-Content -LiteralPath $file -Value @"
function Get-DiscoveredSample {
    'ok'
}

Set-AgentModeFunction -Name 'Set-AgentDiscovered' -Body { 'agent' }
"@ -Encoding UTF8

            $functions = @(Get-FunctionsFromPath -Path $scanDir -RepoRoot $script:TestRepoRoot)

            ($functions.Name -contains 'Get-DiscoveredSample') | Should -Be $true
            ($functions.Name -contains 'Set-AgentDiscovered') | Should -Be $true

            $agentFunc = $functions | Where-Object { $_.Name -eq 'Set-AgentDiscovered' } | Select-Object -First 1
            $agentFunc.UsesSetAgentModeFunction | Should -Be $true
            $agentFunc.HasApprovedVerb | Should -Be $true
        }
    }
}
