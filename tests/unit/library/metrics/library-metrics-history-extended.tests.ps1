<#
tests/unit/library-metrics-history-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-HistoricalMetrics loading and filtering behavior.
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
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
    Import-Module (Join-Path $script:LibPath 'metrics' 'MetricsHistory.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'MetricsHistoryExtended'
    $script:HistoryDir = Join-Path $script:TempDir 'history'
    New-Item -ItemType Directory -Path $script:HistoryDir -Force | Out-Null

    1..4 | ForEach-Object {
        $payload = @{
            Timestamp  = "2024-02-0$_`T00:00:00Z"
            TotalFiles = $_ * 5
        } | ConvertTo-Json
        $file = Join-Path $script:HistoryDir ("metrics-2024020{0}-120000.json" -f $_)
        Set-Content -LiteralPath $file -Value $payload -Encoding UTF8
        (Get-Item -LiteralPath $file).LastWriteTime = Get-Date "2024-02-0$_"
    }
}

AfterAll {
    Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
    Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
    Remove-Module MetricsHistory -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        return
    }

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
}

Describe 'MetricsHistory extended scenarios' {
    Context 'Get-HistoricalMetrics' {
        It 'Returns exactly one snapshot when Limit is 1' {
            $result = Get-HistoricalMetrics -HistoryPath $script:HistoryDir -Limit 1

            $result.Count | Should -Be 1
        }

        It 'Parses TotalFiles values from snapshot JSON' {
            $result = Get-HistoricalMetrics -HistoryPath $script:HistoryDir

            @($result | Where-Object { $_.TotalFiles -gt 0 }).Count | Should -BeGreaterThan 0
        }

        It 'Skips invalid JSON while retaining valid snapshots' {
            $mixedDir = Join-Path $script:TempDir 'mixed-history'
            New-Item -ItemType Directory -Path $mixedDir -Force | Out-Null

            $validA = Join-Path $mixedDir 'metrics-valid-a.json'
            $validB = Join-Path $mixedDir 'metrics-valid-b.json'
            $invalid = Join-Path $mixedDir 'metrics-invalid.json'

            @{
                Timestamp  = '2024-02-01T00:00:00Z'
                TotalFiles = 10
            } | ConvertTo-Json | Set-Content -LiteralPath $validA -Encoding UTF8
            (Get-Item -LiteralPath $validA).LastWriteTime = Get-Date '2024-02-01'

            @{
                Timestamp  = '2024-02-02T00:00:00Z'
                TotalFiles = 20
            } | ConvertTo-Json | Set-Content -LiteralPath $validB -Encoding UTF8
            (Get-Item -LiteralPath $validB).LastWriteTime = Get-Date '2024-02-02'

            Set-Content -LiteralPath $invalid -Value '{ invalid' -Encoding UTF8
            (Get-Item -LiteralPath $invalid).LastWriteTime = Get-Date '2024-02-03'

            $result = Get-HistoricalMetrics -HistoryPath $mixedDir

            $result.Count | Should -Be 2
        }

        It 'Returns an empty array for an empty history directory' {
            $emptyDir = Join-Path $script:TempDir 'empty-history'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null

            $result = Get-HistoricalMetrics -HistoryPath $emptyDir
            if ($null -eq $result) {
                $result = @()
            }

            $result.Count | Should -Be 0
        }

        It 'Emits verbose tracing when PS_PROFILE_DEBUG is level 2' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $originalVerbose = $VerbosePreference
            $env:PS_PROFILE_DEBUG = '2'
            $VerbosePreference = 'Continue'

            try {
                $result = Get-HistoricalMetrics -HistoryPath $script:HistoryDir
                $result.Count | Should -BeGreaterThan 0
            }
            finally {
                $VerbosePreference = $originalVerbose
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Emits level 3 tracing when Limit is applied' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = Get-HistoricalMetrics -HistoryPath $script:HistoryDir -Limit 2
                $result.Count | Should -Be 2
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses Write-StructuredWarning when snapshot JSON cannot be parsed' {
            Enable-TestStructuredLogging

            $mixedDir = Join-Path $script:TempDir 'structured-invalid-history'
            New-Item -ItemType Directory -Path $mixedDir -Force | Out-Null
            @{
                Timestamp  = '2024-02-10T00:00:00Z'
                TotalFiles = 5
            } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $mixedDir 'metrics-valid.json') -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $mixedDir 'metrics-invalid.json') -Value '{ bad-json' -Encoding UTF8

            { Get-HistoricalMetrics -HistoryPath $mixedDir } | Should -Not -Throw
        }

        It 'Warns with Write-Warning when snapshot JSON cannot be parsed without structured logging' {
            $mixedDir = Join-Path $script:TempDir 'warning-invalid-history'
            New-Item -ItemType Directory -Path $mixedDir -Force | Out-Null
            @{
                Timestamp  = '2024-02-11T00:00:00Z'
                TotalFiles = 6
            } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $mixedDir 'metrics-valid.json') -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $mixedDir 'metrics-invalid.json') -Value '{ bad-json' -Encoding UTF8

            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $result = Get-HistoricalMetrics -HistoryPath $mixedDir
                $result.Count | Should -Be 1
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses structured warnings when debug is explicitly disabled' {
            Enable-TestStructuredLogging

            $mixedDir = Join-Path $script:TempDir 'structured-debug-off-history'
            New-Item -ItemType Directory -Path $mixedDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $mixedDir 'metrics-invalid.json') -Value '{ bad-json' -Encoding UTF8

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                { Get-HistoricalMetrics -HistoryPath $mixedDir } | Should -Not -Throw
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Warns at debug level 1 when snapshot JSON cannot be parsed without structured logging' {
            $mixedDir = Join-Path $script:TempDir 'debug1-invalid-history'
            New-Item -ItemType Directory -Path $mixedDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $mixedDir 'metrics-invalid.json') -Value '{ bad-json' -Encoding UTF8

            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                { Get-HistoricalMetrics -HistoryPath $mixedDir } | Should -Not -Throw
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }
}
