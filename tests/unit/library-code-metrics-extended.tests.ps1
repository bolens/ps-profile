<#
tests/unit/library-code-metrics-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for CodeMetrics function counting behavior.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $fileSystemPath = Join-Path $libPath 'file' 'FileSystem.psm1'
    $astParsingPath = Join-Path $libPath 'code-analysis' 'AstParsing.psm1'
    $fileContentPath = Join-Path $libPath 'file' 'FileContent.psm1'
    $collectionsPath = Join-Path $libPath 'utilities' 'Collections.psm1'

    Import-Module $fileSystemPath -DisableNameChecking -Force -Global
    Import-Module $astParsingPath -DisableNameChecking -Force -Global
    Import-Module $fileContentPath -DisableNameChecking -Force -Global
    Import-Module $collectionsPath -DisableNameChecking -Force -Global
    Import-Module (Join-Path $libPath 'metrics' 'CodeMetrics.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'CodeMetricsExtended'
    $script:SampleScript = Join-Path $script:TempRoot 'metrics-sample.ps1'
    @'
function Get-SampleOne {
    'one'
}

function Get-SampleTwo {
    'two'
}
'@ | Set-Content -LiteralPath $script:SampleScript -Encoding UTF8
}

AfterAll {
    Remove-Module CodeMetrics -ErrorAction SilentlyContinue -Force
    Remove-Module FileSystem -ErrorAction SilentlyContinue -Force
    Remove-Module AstParsing -ErrorAction SilentlyContinue -Force
    Remove-Module FileContent -ErrorAction SilentlyContinue -Force
    Remove-Module Collections -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'CodeMetrics extended scenarios' {
    Context 'Get-CodeMetrics' {
        It 'Counts functions declared in a script file' {
            $metrics = Get-CodeMetrics -Path $script:SampleScript

            $metrics.TotalFunctions | Should -BeGreaterOrEqual 2
        }

        It 'Reports per-file metrics for the analyzed script' {
            $metrics = Get-CodeMetrics -Path $script:SampleScript
            $fileMetric = @($metrics.FileMetrics | Where-Object { $_.Path -like '*metrics-sample.ps1' } | Select-Object -First 1)

            @($fileMetric).Count | Should -Be 1
            $fileMetric[0].Functions | Should -BeGreaterOrEqual 2
        }
    }

    Context 'ConvertTo-FileMetricsArray' {
        It 'Returns an empty array for empty generic lists' {
            $list = [System.Collections.Generic.List[object]]::new()

            @(ConvertTo-FileMetricsArray -InputList $list).Count | Should -Be 0
        }
    }
}
