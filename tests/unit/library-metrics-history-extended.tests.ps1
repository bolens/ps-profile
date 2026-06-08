<#
tests/unit/library-metrics-history-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-HistoricalMetrics loading and filtering behavior.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
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
    Remove-Module MetricsHistory -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
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
    }
}
