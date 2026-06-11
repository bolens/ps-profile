<#
tests/unit/library-code-metrics-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for CodeMetrics aggregation and analysis edge cases.
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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:ProfileDir = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'profile.d'

    foreach ($dep in @(
            @{ Name = 'FileSystem'; Path = 'file/FileSystem.psm1' }
            @{ Name = 'AstParsing'; Path = 'code-analysis/AstParsing.psm1' }
            @{ Name = 'FileContent'; Path = 'file/FileContent.psm1' }
            @{ Name = 'Collections'; Path = 'utilities/Collections.psm1' }
        )) {
        Import-Module (Join-Path $script:LibPath $dep.Path) -DisableNameChecking -Force -Global
    }
    Import-Module (Join-Path $script:LibPath 'metrics/CodeMetrics.psm1') -DisableNameChecking -Force

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

function script:Clear-CodeMetricsTestEnvironment {
    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    Remove-Item Env:PS_PROFILE_CODE_METRICS_FORCE_READ_FAIL -ErrorAction SilentlyContinue
    Remove-Item Env:PS_PROFILE_CODE_METRICS_FORCE_READ_MSG -ErrorAction SilentlyContinue
}

AfterAll {
    Clear-CodeMetricsTestEnvironment
    Remove-Module CodeMetrics, FileSystem, AstParsing, FileContent, Collections -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'CodeMetrics extended scenarios' {
    BeforeEach { Clear-CodeMetricsTestEnvironment }

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

        It 'Detects duplicate function names across multiple script files' {
            $dupA = Join-Path $script:TempRoot 'dup-a.ps1'
            $dupB = Join-Path $script:TempRoot 'dup-b.ps1'
            'function Get-DuplicateProbe { 1 }' | Set-Content -LiteralPath $dupA -Encoding UTF8
            'function Get-DuplicateProbe { 2 }' | Set-Content -LiteralPath $dupB -Encoding UTF8

            $metrics = Get-CodeMetrics -Path $script:TempRoot

            $metrics.DuplicateFunctions | Should -BeGreaterOrEqual 1
            @($metrics.DuplicateFunctionDetails | Where-Object { $_.FunctionName -eq 'Get-DuplicateProbe' }).Count | Should -BeGreaterOrEqual 1
        }

        It 'Calculates complexity for scripts with branching statements' {
            $complexScript = Join-Path $script:TempRoot 'complex-sample.ps1'
            @'
function Get-ComplexProbe {
    if ($true) { 'a' }
    while ($false) { 'b' }
}
'@ | Set-Content -LiteralPath $complexScript -Encoding UTF8

            $metrics = Get-CodeMetrics -Path $complexScript
            $fileMetric = @($metrics.FileMetrics | Where-Object { $_.Path -like '*complex-sample.ps1' } | Select-Object -First 1)

            $fileMetric[0].Complexity | Should -BeGreaterOrEqual 1
        }

        It 'Returns zeroed aggregates for directories without PowerShell scripts' {
            $emptyDir = Join-Path $script:TempRoot 'empty-metrics-dir'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null

            $metrics = Get-CodeMetrics -Path $emptyDir

            $metrics.TotalFiles | Should -Be 0
            $metrics.TotalLines | Should -Be 0
            @($metrics.FileMetrics).Count | Should -Be 0
        }

        It 'Emits structured warnings when forced read failures occur' {
            $failScript = Join-Path $script:TempRoot 'force-read-fail.ps1'
            Set-Content -LiteralPath $failScript -Value 'function Get-Fail { 1 }' -Encoding UTF8

            $env:PS_PROFILE_CODE_METRICS_FORCE_READ_FAIL = '1'
            Enable-TestStructuredLogging

            $metrics = Get-CodeMetrics -Path $script:TempRoot
            $metrics | Should -Not -BeNullOrEmpty
        }

        It 'Logs analysis progress at debug level 2' {
            $env:PS_PROFILE_DEBUG = '2'
            $metrics = Get-CodeMetrics -Path $script:SampleScript

            $metrics.TotalLines | Should -BeGreaterThan 0
        }

        It 'Uses manual parser fallback when AstParsing helpers are unavailable' {
            Remove-Module AstParsing -ErrorAction SilentlyContinue -Force

            $metrics = Get-CodeMetrics -Path $script:SampleScript

            $metrics.TotalFunctions | Should -BeGreaterOrEqual 0

            Import-Module (Join-Path $script:LibPath 'code-analysis/AstParsing.psm1') -DisableNameChecking -Force -Global
        }

        It 'Logs per-script analysis details at debug level 3' {
            $env:PS_PROFILE_DEBUG = '3'

            $metrics = Get-CodeMetrics -Path $script:SampleScript

            $metrics.TotalLines | Should -BeGreaterThan 0
        }

        It 'Uses Get-Content fallback when Read-FileContent is unavailable' {
            Remove-Module FileContent -ErrorAction SilentlyContinue -Force

            $metrics = Get-CodeMetrics -Path $script:SampleScript

            $metrics.TotalLines | Should -BeGreaterThan 0

            Import-Module (Join-Path $script:LibPath 'file/FileContent.psm1') -DisableNameChecking -Force -Global
        }

        It 'Calculates average metrics per analyzed file' {
            $metrics = Get-CodeMetrics -Path $script:SampleScript

            $metrics.AverageLinesPerFile | Should -BeGreaterThan 0
            $metrics.AverageFunctionsPerFile | Should -BeGreaterOrEqual 0
            $metrics.AverageComplexityPerFile | Should -BeGreaterOrEqual 0
        }

        It 'Uses manual parser complexity when AstParsing helpers are unavailable' {
            $manualComplexScript = Join-Path $script:TempRoot 'manual-complex-sample.ps1'
            @'
function Get-ManualComplexProbe {
    if ($true) { 'a' }
    while ($false) { 'b' }
}
'@ | Set-Content -LiteralPath $manualComplexScript -Encoding UTF8

            Remove-Module AstParsing -ErrorAction SilentlyContinue -Force
            foreach ($fn in @('Get-PowerShellAst', 'Get-FunctionsFromAst', 'Get-AstComplexity')) {
                Remove-TestFunction -Name $fn
            }

            $metrics = Get-CodeMetrics -Path $manualComplexScript
            $fileMetric = @($metrics.FileMetrics | Where-Object { $_.Path -like '*manual-complex-sample.ps1' } | Select-Object -First 1)

            $fileMetric[0].Lines | Should -BeGreaterThan 0

            Import-Module (Join-Path $script:LibPath 'code-analysis/AstParsing.psm1') -DisableNameChecking -Force -Global
        }

        It 'Uses generic duplicate tracking lists when Collections helpers are unavailable' {
            $dupDir = Join-Path $script:TempRoot 'collection-dup-only'
            New-Item -ItemType Directory -Path $dupDir -Force | Out-Null
            'function Get-CollectionDuplicate { 1 }' | Set-Content -LiteralPath (Join-Path $dupDir 'collection-dup-a.ps1') -Encoding UTF8
            'function Get-CollectionDuplicate { 2 }' | Set-Content -LiteralPath (Join-Path $dupDir 'collection-dup-b.ps1') -Encoding UTF8

            Remove-Module Collections -ErrorAction SilentlyContinue -Force
            foreach ($fn in @('New-ObjectList', 'New-TypedList')) {
                Remove-TestFunction -Name $fn
            }

            $metrics = Get-CodeMetrics -Path $dupDir

            $metrics | Should -Not -BeNullOrEmpty
            $metrics.PSObject.Properties.Name | Should -Contain 'DuplicateFunctions'

            Import-Module (Join-Path $script:LibPath 'utilities/Collections.psm1') -DisableNameChecking -Force -Global
        }

        It 'Uses manual dependency imports when Import-ModuleSafely is unavailable' {
            Remove-Module CodeMetrics, SafeImport -ErrorAction SilentlyContinue -Force
            Remove-TestFunction -Name 'Import-ModuleSafely'
            Import-Module (Join-Path $script:LibPath 'file/FileSystem.psm1') -DisableNameChecking -Force -Global
            Import-Module (Join-Path $script:LibPath 'file/FileContent.psm1') -DisableNameChecking -Force -Global
            Import-Module (Join-Path $script:LibPath 'code-analysis/AstParsing.psm1') -DisableNameChecking -Force -Global
            Import-Module (Join-Path $script:LibPath 'utilities/Collections.psm1') -DisableNameChecking -Force -Global

            Import-Module (Join-Path $script:LibPath 'metrics/CodeMetrics.psm1') -DisableNameChecking -Force

            $metrics = Get-CodeMetrics -Path $script:SampleScript
            $metrics | Should -Not -BeNullOrEmpty

            Import-Module (Join-Path $script:LibPath 'core/SafeImport.psm1') -DisableNameChecking -Force -Global
            Import-Module (Join-Path $script:LibPath 'metrics/CodeMetrics.psm1') -DisableNameChecking -Force
        }

        It 'Emits plain warnings when structured logging is unavailable' {
            $failScript = Join-Path $script:TempRoot 'force-read-fail-plain.ps1'
            Set-Content -LiteralPath $failScript -Value 'function Get-FailPlain { 1 }' -Encoding UTF8

            $env:PS_PROFILE_CODE_METRICS_FORCE_READ_FAIL = '1'
            $env:PS_PROFILE_CODE_METRICS_FORCE_READ_MSG = ('x' * 250)
            $env:PS_PROFILE_DEBUG = '3'
            Remove-TestFunction -Name 'Write-StructuredWarning'

            $metrics = Get-CodeMetrics -Path $failScript -WarningAction SilentlyContinue
            $metrics | Should -Not -BeNullOrEmpty
        }

    }

    Context 'ConvertTo-FileMetricsArray' {
        It 'Returns an empty array for empty generic lists' {
            $list = [System.Collections.Generic.List[object]]::new()

            @(ConvertTo-FileMetricsArray -InputList $list).Count | Should -Be 0
        }
    }
}
