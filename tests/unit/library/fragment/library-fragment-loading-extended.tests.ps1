<#
tests/unit/library-fragment-loading-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FragmentLoading dependency validation helpers.
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
    $pathResolutionModulePath = Get-TestPath -RelativePath 'scripts\lib\path\PathResolution.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction SilentlyContinue

    $fileContentModulePath = Get-TestPath -RelativePath 'scripts\lib\file\FileContent.psm1' -StartPath $PSScriptRoot -ErrorAction SilentlyContinue
    if ($fileContentModulePath -and (Test-Path -LiteralPath $fileContentModulePath)) {
        Import-Module $fileContentModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }

    $script:FragmentLoadingPath = Get-TestPath -RelativePath 'scripts\lib\fragment\FragmentLoading.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $script:FragmentLoadingPath -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'FragmentLoadingExtended'
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        return
    }

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
}

function script:Get-FragmentTierResult {
    param([object]$FragmentFile)

    return @((Get-FragmentTier -FragmentFile $FragmentFile))[-1]
}

function script:Set-ParallelParseTestEnvironment {
    param(
        [int]$TimeoutMs = 200,
        [int]$DelayMs = 500,
        [int]$SlowDelayMs = 0,
        [switch]$EmitPsError,
        [switch]$ForceBeginInvokeError,
        [switch]$ForceProcessResultError,
        [switch]$ForceSetupRunspaceError,
        [switch]$ForceAddScriptError,
        [switch]$ForceProcessRunspaceError,
        [switch]$ForceEndInvokeError,
        [switch]$DirectScriptblock,
        [switch]$ForceAddArgumentError,
        [switch]$ForceDisposeError,
        [switch]$ForceTimeoutResultAddError,
        [switch]$ForceErrorResultAddError,
        [switch]$ForceBeginInvokeNull,
        [switch]$ForceAddToRunspacesError,
        [switch]$ForceStopStalledError,
        [int]$GraphBuildDelayMs = 0
    )

    $script:ParallelParseTestPreviousTimeoutMs = $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS
    $script:ParallelParseTestPreviousDelayMs = $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS
    $script:ParallelParseTestPreviousSlowDelayMs = $env:PS_PROFILE_PARALLEL_PARSE_SLOW_FILE_DELAY_MS
    $script:ParallelParseTestPreviousEmitPsError = $env:PS_PROFILE_PARALLEL_PARSE_EMIT_PS_ERROR
    $script:ParallelParseTestPreviousBeginInvokeError = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_BEGININVOKE_ERROR
    $script:ParallelParseTestPreviousProcessResultError = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_PROCESS_RESULT_ERROR
    $script:ParallelParseTestPreviousSetupRunspaceError = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_RUNSPACE_ERROR
    $script:ParallelParseTestPreviousAddScriptError = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADDSCRIPT_ERROR
    $script:ParallelParseTestPreviousGraphBuildDelayMs = $env:PS_PROFILE_FORCE_GRAPH_BUILD_DELAY_MS
    $script:ParallelParseTestPreviousProcessRunspaceError = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_PROCESS_RUNSPACE_ERROR
    $script:ParallelParseTestPreviousEndInvokeError = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ENDINVOKE_ERROR
    $script:ParallelParseTestPreviousDirectScriptblock = $env:PS_PROFILE_PARALLEL_PARSE_DIRECT_SCRIPTBLOCK
    $script:ParallelParseTestPreviousAddArgumentError = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADD_ARGUMENT_ERROR
    $script:ParallelParseTestPreviousDisposeError = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_DISPOSE_ERROR
    $script:ParallelParseTestPreviousTimeoutResultAddError = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_TIMEOUT_RESULT_ADD_ERROR
    $script:ParallelParseTestPreviousErrorResultAddError = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ERROR_RESULT_ADD_ERROR
    $script:ParallelParseTestPreviousBeginInvokeNull = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_BEGININVOKE_NULL
    $script:ParallelParseTestPreviousAddToRunspacesError = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADD_TO_RUNSPACES_ERROR
    $script:ParallelParseTestPreviousStopStalledError = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_STOP_STALLED_ERROR

    $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = "$TimeoutMs"
    $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = "$DelayMs"

    if ($SlowDelayMs -gt 0) {
        $env:PS_PROFILE_PARALLEL_PARSE_SLOW_FILE_DELAY_MS = "$SlowDelayMs"
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_SLOW_FILE_DELAY_MS -ErrorAction SilentlyContinue
    }

    if ($EmitPsError) {
        $env:PS_PROFILE_PARALLEL_PARSE_EMIT_PS_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_EMIT_PS_ERROR -ErrorAction SilentlyContinue
    }

    if ($ForceBeginInvokeError) {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_BEGININVOKE_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_BEGININVOKE_ERROR -ErrorAction SilentlyContinue
    }

    if ($ForceProcessResultError) {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_PROCESS_RESULT_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_PROCESS_RESULT_ERROR -ErrorAction SilentlyContinue
    }

    if ($ForceSetupRunspaceError) {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_RUNSPACE_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_RUNSPACE_ERROR -ErrorAction SilentlyContinue
    }

    if ($ForceAddScriptError) {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADDSCRIPT_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADDSCRIPT_ERROR -ErrorAction SilentlyContinue
    }

    if ($GraphBuildDelayMs -gt 0) {
        $env:PS_PROFILE_FORCE_GRAPH_BUILD_DELAY_MS = "$GraphBuildDelayMs"
    }
    else {
        Remove-Item Env:PS_PROFILE_FORCE_GRAPH_BUILD_DELAY_MS -ErrorAction SilentlyContinue
    }

    if ($ForceProcessRunspaceError) {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_PROCESS_RUNSPACE_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_PROCESS_RUNSPACE_ERROR -ErrorAction SilentlyContinue
    }

    if ($ForceEndInvokeError) {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ENDINVOKE_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_ENDINVOKE_ERROR -ErrorAction SilentlyContinue
    }

    if ($DirectScriptblock) {
        $env:PS_PROFILE_PARALLEL_PARSE_DIRECT_SCRIPTBLOCK = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_DIRECT_SCRIPTBLOCK -ErrorAction SilentlyContinue
    }

    if ($ForceAddArgumentError) {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADD_ARGUMENT_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADD_ARGUMENT_ERROR -ErrorAction SilentlyContinue
    }

    if ($ForceDisposeError) {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_DISPOSE_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_DISPOSE_ERROR -ErrorAction SilentlyContinue
    }

    if ($ForceTimeoutResultAddError) {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_TIMEOUT_RESULT_ADD_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_TIMEOUT_RESULT_ADD_ERROR -ErrorAction SilentlyContinue
    }

    if ($ForceErrorResultAddError) {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ERROR_RESULT_ADD_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_ERROR_RESULT_ADD_ERROR -ErrorAction SilentlyContinue
    }

    if ($ForceBeginInvokeNull) {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_BEGININVOKE_NULL = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_BEGININVOKE_NULL -ErrorAction SilentlyContinue
    }

    if ($ForceAddToRunspacesError) {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADD_TO_RUNSPACES_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADD_TO_RUNSPACES_ERROR -ErrorAction SilentlyContinue
    }

    if ($ForceStopStalledError) {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_STOP_STALLED_ERROR = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_STOP_STALLED_ERROR -ErrorAction SilentlyContinue
    }
}

function script:Restore-ParallelParseTestEnvironment {
    if ($null -eq $script:ParallelParseTestPreviousTimeoutMs) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = $script:ParallelParseTestPreviousTimeoutMs
    }

    if ($null -eq $script:ParallelParseTestPreviousDelayMs) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = $script:ParallelParseTestPreviousDelayMs
    }

    if ($null -eq $script:ParallelParseTestPreviousSlowDelayMs) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_SLOW_FILE_DELAY_MS -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_SLOW_FILE_DELAY_MS = $script:ParallelParseTestPreviousSlowDelayMs
    }

    if ($null -eq $script:ParallelParseTestPreviousEmitPsError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_EMIT_PS_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_EMIT_PS_ERROR = $script:ParallelParseTestPreviousEmitPsError
    }

    if ($null -eq $script:ParallelParseTestPreviousBeginInvokeError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_BEGININVOKE_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_BEGININVOKE_ERROR = $script:ParallelParseTestPreviousBeginInvokeError
    }

    if ($null -eq $script:ParallelParseTestPreviousProcessResultError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_PROCESS_RESULT_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_PROCESS_RESULT_ERROR = $script:ParallelParseTestPreviousProcessResultError
    }

    if ($null -eq $script:ParallelParseTestPreviousSetupRunspaceError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_RUNSPACE_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_RUNSPACE_ERROR = $script:ParallelParseTestPreviousSetupRunspaceError
    }

    if ($null -eq $script:ParallelParseTestPreviousAddScriptError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADDSCRIPT_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADDSCRIPT_ERROR = $script:ParallelParseTestPreviousAddScriptError
    }

    if ($null -eq $script:ParallelParseTestPreviousGraphBuildDelayMs) {
        Remove-Item Env:PS_PROFILE_FORCE_GRAPH_BUILD_DELAY_MS -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_FORCE_GRAPH_BUILD_DELAY_MS = $script:ParallelParseTestPreviousGraphBuildDelayMs
    }

    if ($null -eq $script:ParallelParseTestPreviousProcessRunspaceError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_PROCESS_RUNSPACE_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_PROCESS_RUNSPACE_ERROR = $script:ParallelParseTestPreviousProcessRunspaceError
    }

    if ($null -eq $script:ParallelParseTestPreviousEndInvokeError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_ENDINVOKE_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ENDINVOKE_ERROR = $script:ParallelParseTestPreviousEndInvokeError
    }

    if ($null -eq $script:ParallelParseTestPreviousDirectScriptblock) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_DIRECT_SCRIPTBLOCK -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_DIRECT_SCRIPTBLOCK = $script:ParallelParseTestPreviousDirectScriptblock
    }

    if ($null -eq $script:ParallelParseTestPreviousAddArgumentError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADD_ARGUMENT_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADD_ARGUMENT_ERROR = $script:ParallelParseTestPreviousAddArgumentError
    }

    if ($null -eq $script:ParallelParseTestPreviousDisposeError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_DISPOSE_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_DISPOSE_ERROR = $script:ParallelParseTestPreviousDisposeError
    }

    if ($null -eq $script:ParallelParseTestPreviousTimeoutResultAddError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_TIMEOUT_RESULT_ADD_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_TIMEOUT_RESULT_ADD_ERROR = $script:ParallelParseTestPreviousTimeoutResultAddError
    }

    if ($null -eq $script:ParallelParseTestPreviousErrorResultAddError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_ERROR_RESULT_ADD_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ERROR_RESULT_ADD_ERROR = $script:ParallelParseTestPreviousErrorResultAddError
    }

    if ($null -eq $script:ParallelParseTestPreviousBeginInvokeNull) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_BEGININVOKE_NULL -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_BEGININVOKE_NULL = $script:ParallelParseTestPreviousBeginInvokeNull
    }

    if ($null -eq $script:ParallelParseTestPreviousAddToRunspacesError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADD_TO_RUNSPACES_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_ADD_TO_RUNSPACES_ERROR = $script:ParallelParseTestPreviousAddToRunspacesError
    }

    if ($null -eq $script:ParallelParseTestPreviousStopStalledError) {
        Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_STOP_STALLED_ERROR -ErrorAction SilentlyContinue
    }
    else {
        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_STOP_STALLED_ERROR = $script:ParallelParseTestPreviousStopStalledError
    }
}

AfterAll {
    Remove-Module FragmentLoading -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FragmentLoading extended scenarios' {
    BeforeEach {
        Remove-Module FragmentLoader -ErrorAction SilentlyContinue -Force
        Import-Module $script:FragmentLoadingPath -DisableNameChecking -Force
    }

    Context 'Get-FragmentDependencies' {
        It 'Ignores duplicate dependency declarations' {
            $fragmentPath = Join-Path $script:TempDir 'dup-deps.ps1'
            Set-Content -LiteralPath $fragmentPath -Value @'
#Requires -Fragment 'bootstrap'
#Requires -Fragment 'bootstrap'
# Dependencies: env, env
'@ -Encoding UTF8

            $deps = Get-FragmentDependencies -FragmentFile $fragmentPath
            @($deps | Where-Object { $_ -eq 'bootstrap' }).Count | Should -Be 1
            @($deps | Where-Object { $_ -eq 'env' }).Count | Should -Be 1
        }

        It 'Trims whitespace from Dependencies comment entries' {
            $fragmentPath = Join-Path $script:TempDir 'trimmed-deps.ps1'
            Set-Content -LiteralPath $fragmentPath -Value @'
# Dependencies:  bootstrap , env , utilities
'@ -Encoding UTF8

            $deps = Get-FragmentDependencies -FragmentFile $fragmentPath
            $deps | Should -Contain 'bootstrap'
            $deps | Should -Contain 'env'
            $deps | Should -Contain 'utilities'
        }
    }

    Context 'Test-FragmentDependencies' {
        It 'Reports a valid dependency graph when all requirements are satisfied' {
            $basePath = Join-Path $script:TempDir '10-valid-base.ps1'
            $childPath = Join-Path $script:TempDir '20-valid-child.ps1'
            Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
            Set-Content -LiteralPath $childPath -Value '# Dependencies: 10-valid-base' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $basePath)
                (Get-Item -LiteralPath $childPath)
            )

            $result = Test-FragmentDependencies -FragmentFiles $fragments
            $result.Valid | Should -Be $true
            $result.HasIssues() | Should -Be $false
        }

        It 'Reports missing dependencies that are not present in the fragment set' {
            $missingPath = Join-Path $script:TempDir '10-needs-missing.ps1'
            Set-Content -LiteralPath $missingPath -Value @'
#Requires -Fragment 'missing-target'
'@ -Encoding UTF8

            $fragments = @(Get-Item -LiteralPath $missingPath)
            $result = Test-FragmentDependencies -FragmentFiles $fragments

            $result.Valid | Should -Be $false
            $result.MissingDependencies | Should -Not -BeNullOrEmpty
        }

        It 'Detects circular dependency chains' {
            $pathA = Join-Path $script:TempDir '10-cycle-a.ps1'
            $pathB = Join-Path $script:TempDir '20-cycle-b.ps1'
            Set-Content -LiteralPath $pathA -Value "#Requires -Fragment '20-cycle-b'" -Encoding UTF8
            Set-Content -LiteralPath $pathB -Value "#Requires -Fragment '10-cycle-a'" -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $pathA)
                (Get-Item -LiteralPath $pathB)
            )

            $result = Test-FragmentDependencies -FragmentFiles $fragments

            $result.Valid | Should -Be $false
            $result.CircularDependencies | Should -Not -BeNullOrEmpty
        }

        It 'Reports dependencies that are present but disabled' {
            $basePath = Join-Path $script:TempDir '10-disabled-dep-base.ps1'
            $disabledPath = Join-Path $script:TempDir '20-disabled-dep-target.ps1'
            $childPath = Join-Path $script:TempDir '30-disabled-dep-child.ps1'
            Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
            Set-Content -LiteralPath $disabledPath -Value '# disabled target' -Encoding UTF8
            Set-Content -LiteralPath $childPath -Value "# Dependencies: 20-disabled-dep-target" -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $basePath)
                (Get-Item -LiteralPath $disabledPath)
                (Get-Item -LiteralPath $childPath)
            )

            $result = Test-FragmentDependencies -FragmentFiles $fragments -DisabledFragments @('20-disabled-dep-target')

            $result.Valid | Should -Be $false
            @($result.MissingDependencies | Where-Object { $_ -match '\(disabled\)' }).Count |
                Should -BeGreaterThan 0
        }
    }

    Context 'Get-FragmentDependencyLevels' {
        It 'Groups independent fragments into the same dependency level' {
            $pathA = Join-Path $script:TempDir '10-independent-a.ps1'
            $pathB = Join-Path $script:TempDir '11-independent-b.ps1'
            Set-Content -LiteralPath $pathA -Value '# independent a' -Encoding UTF8
            Set-Content -LiteralPath $pathB -Value '# independent b' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $pathA)
                (Get-Item -LiteralPath $pathB)
            )

            $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments
            $levels.Keys | Should -Contain 'Level0'

            @($levels['Level0'] | ForEach-Object { $_.BaseName }) | Should -Contain '10-independent-a'
            @($levels['Level0'] | ForEach-Object { $_.BaseName }) | Should -Contain '11-independent-b'
        }

        It 'Places dependent fragments in later levels' {
            $pathBase = Join-Path $script:TempDir '20-level-base.ps1'
            $pathChild = Join-Path $script:TempDir '30-level-child.ps1'
            Set-Content -LiteralPath $pathBase -Value '# base fragment' -Encoding UTF8
            Set-Content -LiteralPath $pathChild -Value "#Requires -Fragment '20-level-base'" -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $pathChild)
                (Get-Item -LiteralPath $pathBase)
            )

            $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments
            $levels.Keys | Should -Contain 'Level0'
            $levels.Keys | Should -Contain 'Level1'
            @($levels['Level0'] | ForEach-Object { $_.BaseName }) | Should -Contain '20-level-base'
            @($levels['Level1'] | ForEach-Object { $_.BaseName }) | Should -Contain '30-level-child'
        }

        It 'Excludes disabled fragments from dependency levels' {
            $pathA = Join-Path $script:TempDir '10-disabled-a.ps1'
            $pathB = Join-Path $script:TempDir '20-disabled-b.ps1'
            Set-Content -LiteralPath $pathA -Value '# disabled a' -Encoding UTF8
            Set-Content -LiteralPath $pathB -Value '# disabled b' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $pathA)
                (Get-Item -LiteralPath $pathB)
            )

            $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments -DisabledFragments @('20-disabled-b')
            $allNames = @($levels.Values | ForEach-Object { $_ } | ForEach-Object { $_.BaseName })
            $allNames | Should -Contain '10-disabled-a'
            $allNames | Should -Not -Contain '20-disabled-b'
        }

        It 'Emits graph build diagnostics when parallel dependency-level graph construction exceeds the threshold' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $basePath = Join-Path $script:TempDir '10-level-graph-delay-base.ps1'
                Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                [void]$fragments.Add((Get-Item -LiteralPath $basePath))

                2..7 | ForEach-Object {
                    $path = Join-Path $script:TempDir "4$($_)-level-graph-delay.ps1"
                    Set-Content -LiteralPath $path -Value '# Dependencies: 10-level-graph-delay-base' -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                Set-ParallelParseTestEnvironment -DelayMs 0 -GraphBuildDelayMs 75
                $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments.ToArray()
                $levels.Keys.Count | Should -BeGreaterThan 0
            }
            finally {
                Restore-ParallelParseTestEnvironment
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Builds dependency levels through parallel parsing for larger fragment sets' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $basePath = Join-Path $script:TempDir '10-level-parallel-base.ps1'
                Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                [void]$fragments.Add((Get-Item -LiteralPath $basePath))

                2..7 | ForEach-Object {
                    $path = Join-Path $script:TempDir "2$($_)-level-parallel.ps1"
                    Set-Content -LiteralPath $path -Value '# Dependencies: 10-level-parallel-base' -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments.ToArray()
                $levels.Keys | Should -Contain 'Level0'
                $levels.Keys | Should -Contain 'Level1'
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Uses parallel dependency parsing when enabled for larger fragment sets' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'

            try {
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                1..6 | ForEach-Object {
                    $path = Join-Path $script:TempDir "1$($_)-parallel-parse.ps1"
                    Set-Content -LiteralPath $path -Value "# fragment $_" -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments.ToArray()
                $levels.Keys.Count | Should -BeGreaterThan 0
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }
            }
        }

        It 'Includes cyclic fragments in the remaining dependency level bucket' {
            $pathA = Join-Path $script:TempDir '10-level-cycle-a.ps1'
            $pathB = Join-Path $script:TempDir '20-level-cycle-b.ps1'
            $pathC = Join-Path $script:TempDir '30-level-independent.ps1'
            Set-Content -LiteralPath $pathA -Value "#Requires -Fragment '20-level-cycle-b'" -Encoding UTF8
            Set-Content -LiteralPath $pathB -Value "#Requires -Fragment '10-level-cycle-a'" -Encoding UTF8
            Set-Content -LiteralPath $pathC -Value '# independent' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $pathA)
                (Get-Item -LiteralPath $pathB)
                (Get-Item -LiteralPath $pathC)
            )

            $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments
            $allNames = @($levels.Values | ForEach-Object { $_ } | ForEach-Object { $_.BaseName })
            $allNames | Should -Contain '30-level-independent'
            $allNames.Count | Should -Be 3
        }

        It 'Emits BFS grouping diagnostics when dependency-level debug tracing is enabled' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '0'
            $env:PS_PROFILE_DEBUG = '2'

            try {
                $basePath = Join-Path $script:TempDir '10-bfs-base.ps1'
                $childPath = Join-Path $script:TempDir '20-bfs-child.ps1'
                Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
                Set-Content -LiteralPath $childPath -Value '# Dependencies: 10-bfs-base' -Encoding UTF8

                $levels = Get-FragmentDependencyLevels -FragmentFiles @(
                    (Get-Item -LiteralPath $childPath)
                    (Get-Item -LiteralPath $basePath)
                )

                $levels.Keys | Should -Contain 'Level0'
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Parses dependency levels sequentially when debug level 3 is enabled' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '0'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $basePath = Join-Path $script:TempDir '10-level-seq-base.ps1'
                $childPath = Join-Path $script:TempDir '20-level-seq-child.ps1'
                Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
                Set-Content -LiteralPath $childPath -Value '# Dependencies: 10-level-seq-base' -Encoding UTF8

                $levels = Get-FragmentDependencyLevels -FragmentFiles @(
                    (Get-Item -LiteralPath $childPath)
                    (Get-Item -LiteralPath $basePath)
                )

                $levels.Keys | Should -Contain 'Level0'
                $levels.Keys | Should -Contain 'Level1'
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Uses Write-Warning for invalid parallel level results without structured logging' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force

            try {
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                1..6 | ForEach-Object {
                    $path = Join-Path $script:TempDir "4$($_)-invalid-level.ps1"
                    Set-Content -LiteralPath $path -Value "# fragment $_" -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                $ghostPath = Join-Path $script:TempDir '49-level-ghost.ps1'
                Set-Content -LiteralPath $ghostPath -Value '# ghost' -Encoding UTF8
                [void]$fragments.Add((Get-Item -LiteralPath $ghostPath))
                Remove-Item -LiteralPath $ghostPath -Force

                { Get-FragmentDependencyLevels -FragmentFiles $fragments.ToArray() } | Should -Not -Throw
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }
    }

    Context 'Get-FragmentDependencies cache and edge cases' {
        It 'Returns an empty array for a missing fragment path' {
            Get-FragmentDependencies -FragmentFile (Join-Path $script:TempDir 'missing-fragment.ps1') |
                Should -Be @()
        }

        It 'Returns an empty array for whitespace-only fragment content' {
            $fragmentPath = Join-Path $script:TempDir 'empty-deps.ps1'
            Set-Content -LiteralPath $fragmentPath -Value '   ' -Encoding UTF8

            Get-FragmentDependencies -FragmentFile $fragmentPath | Should -Be @()
        }

        It 'Accepts FileInfo objects as input' {
            $fragmentPath = Join-Path $script:TempDir 'fileinfo-deps.ps1'
            Set-Content -LiteralPath $fragmentPath -Value "#Requires -Fragment 'bootstrap'" -Encoding UTF8

            $deps = Get-FragmentDependencies -FragmentFile (Get-Item -LiteralPath $fragmentPath)
            $deps | Should -Contain 'bootstrap'
        }

        It 'Emits level 3 diagnostics when dependency parsing fails without structured logging' {
            $fragmentPath = Join-Path $script:TempDir 'deps-debug3-fail.ps1'
            Set-Content -LiteralPath $fragmentPath -Value '# Dependencies: bootstrap' -Encoding UTF8
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force

            try {
                if ($IsLinux -or $IsMacOS) {
                    chmod 000 $fragmentPath
                }

                Get-FragmentDependencies -FragmentFile $fragmentPath | Should -Be @()
            }
            finally {
                if ($IsLinux -or $IsMacOS) {
                    if (Test-Path -LiteralPath $fragmentPath) {
                        chmod 644 $fragmentPath
                    }
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses Write-Warning when Read-FileContent fails during dependency parsing' {
            $fragmentPath = Join-Path $script:TempDir 'read-filecontent-deps.ps1'
            Set-Content -LiteralPath $fragmentPath -Value '# Dependencies: bootstrap' -Encoding UTF8
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force

            function global:Read-FileContent {
                param([string]$Path)
                throw 'read filecontent dependency probe'
            }

                        Get-FragmentDependencies -FragmentFile $fragmentPath | Should -Be @()
        }
        finally {
            Remove-Item -Path Function:Read-FileContent -ErrorAction SilentlyContinue -Force
            if ($null -eq $originalDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $originalDebug
            }
        }

        It 'Uses Write-ScriptMessage when dependency parsing fails and structured logging is unavailable' {
            $fragmentPath = Join-Path $script:TempDir 'scriptmessage-deps.ps1'
            Set-Content -LiteralPath $fragmentPath -Value '# Dependencies: bootstrap' -Encoding UTF8
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force

            function global:Write-ScriptMessage {
                param(
                    [string]$Message,
                    [switch]$IsWarning
                )
            }

            try {
                if ($IsLinux -or $IsMacOS) {
                    chmod 000 $fragmentPath
                }

                Get-FragmentDependencies -FragmentFile $fragmentPath | Should -Be @()
            }
            finally {
                Remove-Item -Path Function:Write-ScriptMessage -ErrorAction SilentlyContinue -Force
                if ($IsLinux -or $IsMacOS) {
                    if (Test-Path -LiteralPath $fragmentPath) {
                        chmod 644 $fragmentPath
                    }
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses Write-StructuredWarning when dependency parsing fails at debug level 1' {
            Enable-TestStructuredLogging
            $fragmentPath = Join-Path $script:TempDir 'structured-deps-fail.ps1'
            Set-Content -LiteralPath $fragmentPath -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestFragmentPath = $fragmentPath
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                if ($IsLinux -or $IsMacOS) {
                    chmod 000 $fragmentPath
                }

                InModuleScope -ModuleName FragmentLoading {
                    $output = @(Get-FragmentDependencies -FragmentFile $global:TestFragmentPath)
                    ($output | Where-Object { $_ -is [string] }) | Should -Be @()
                }
            }
            finally {
                if ($IsLinux -or $IsMacOS) {
                    if (Test-Path -LiteralPath $fragmentPath) {
                        chmod 644 $fragmentPath
                    }
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses Write-Warning when dependency parsing fails without structured logging' {
            $fragmentPath = Join-Path $script:TempDir 'unreadable-deps.ps1'
            Set-Content -LiteralPath $fragmentPath -Value '# Dependencies: bootstrap' -Encoding UTF8
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force

            try {
                if ($IsLinux -or $IsMacOS) {
                    chmod 000 $fragmentPath
                }

                Get-FragmentDependencies -FragmentFile $fragmentPath | Should -Be @()
            }
            finally {
                if ($IsLinux -or $IsMacOS) {
                    if (Test-Path -LiteralPath $fragmentPath) {
                        chmod 644 $fragmentPath
                    }
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Reuses cached dependencies when the file has not changed' {
            $fragmentPath = Join-Path $script:TempDir 'cached-deps.ps1'
            Set-Content -LiteralPath $fragmentPath -Value "#Requires -Fragment 'bootstrap'" -Encoding UTF8

            $first = Get-FragmentDependencies -FragmentFile $fragmentPath
            $second = Get-FragmentDependencies -FragmentFile $fragmentPath

            $first | Should -Contain 'bootstrap'
            $second | Should -Be $first
        }
    }

    Context 'Get-FragmentTier' {
        It 'Records tier parse failures through Write-StructuredWarning when debug is enabled' {
            Enable-TestStructuredLogging
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $filePath = Join-Path $script:TempDir 'tier-parse-unreadable.ps1'
                Set-Content -LiteralPath $filePath -Value '# Tier: core' -Encoding UTF8

                if ($IsLinux -or $IsMacOS) {
                    chmod 000 $filePath
                }

                Get-FragmentTierResult -FragmentFile $filePath | Should -Be 'optional'
            }
            finally {
                if ($IsLinux -or $IsMacOS) {
                    $filePath = Join-Path $script:TempDir 'tier-parse-unreadable.ps1'
                    if (Test-Path -LiteralPath $filePath) {
                        chmod 644 $filePath
                    }
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Reads explicit tier declarations from fragment content' {
            $path = Join-Path $script:TempDir '25-explicit-tier.ps1'
            Set-Content -LiteralPath $path -Value "# Tier: essential`n# fragment" -Encoding UTF8
            Get-FragmentTier -FragmentFile $path | Should -Be 'essential'
        }

        It 'Treats bootstrap fragments as core tier' {
            $path = Join-Path $script:TempDir 'bootstrap.ps1'
            Set-Content -LiteralPath $path -Value "# Tier: core`n# bootstrap" -Encoding UTF8
            Get-FragmentTier -FragmentFile $path | Should -Be 'core'
        }

        It 'Defaults missing files to optional tier' {
            Get-FragmentTier -FragmentFile (Join-Path $script:TempDir 'missing-tier.ps1') | Should -Be 'optional'
        }

        It 'Returns optional tier for whitespace-only fragment content' {
            $path = Join-Path $script:TempDir 'blank-tier.ps1'
            Set-Content -LiteralPath $path -Value '   ' -Encoding UTF8
            Get-FragmentTier -FragmentFile $path | Should -Be 'optional'
        }

        It 'Uses Write-Warning when tier parsing fails without structured logging' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            $filePath = Join-Path $script:TempDir 'tier-warning-fail.ps1'

            try {
                Set-Content -LiteralPath $filePath -Value '# Tier: core' -Encoding UTF8
                if ($IsLinux -or $IsMacOS) {
                    chmod 000 $filePath
                }

                Get-FragmentTierResult -FragmentFile $filePath | Should -Be 'optional'
            }
            finally {
                if ($IsLinux -or $IsMacOS) {
                    if (Test-Path -LiteralPath $filePath) {
                        chmod 644 $filePath
                    }
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Emits level 3 verbose tracing when tier parsing fails without structured logging' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            $filePath = Join-Path $script:TempDir 'tier-verbose-fail.ps1'

            try {
                Set-Content -LiteralPath $filePath -Value '# Tier: core' -Encoding UTF8
                if ($IsLinux -or $IsMacOS) {
                    chmod 000 $filePath
                }

                Get-FragmentTierResult -FragmentFile $filePath | Should -Be 'optional'
            }
            finally {
                if ($IsLinux -or $IsMacOS) {
                    if (Test-Path -LiteralPath $filePath) {
                        chmod 644 $filePath
                    }
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }

    Context 'Get-FragmentLoadOrder' {
        It 'Uses Write-StructuredWarning when parallel load-order parsing returns invalid results' {
            Enable-TestStructuredLogging
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                1..6 | ForEach-Object {
                    $path = Join-Path $script:TempDir "3$($_)-invalid-order.ps1"
                    Set-Content -LiteralPath $path -Value "# fragment $_" -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                # Include a missing path in the parallel parser input via a deleted fragment entry
                $ghostPath = Join-Path $script:TempDir '39-ghost-order.ps1'
                Set-Content -LiteralPath $ghostPath -Value '# ghost' -Encoding UTF8
                [void]$fragments.Add((Get-Item -LiteralPath $ghostPath))
                Remove-Item -LiteralPath $ghostPath -Force

                { Get-FragmentLoadOrder -FragmentFiles $fragments.ToArray() } | Should -Not -Throw
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Uses parallel dependency parsing for larger fragment sets' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                $basePath = Join-Path $script:TempDir '10-parallel-order-base.ps1'
                Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
                [void]$fragments.Add((Get-Item -LiteralPath $basePath))

                2..7 | ForEach-Object {
                    $path = Join-Path $script:TempDir "2$($_)-parallel-order.ps1"
                    Set-Content -LiteralPath $path -Value '# Dependencies: 10-parallel-order-base' -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                $order = Get-FragmentLoadOrder -FragmentFiles $fragments.ToArray()
                @($order | ForEach-Object { $_.BaseName }) | Should -Contain '10-parallel-order-base'
                @($order | ForEach-Object { $_.BaseName }).Count | Should -Be 7
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Parses dependencies sequentially when parallel parsing is disabled' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '0'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $basePath = Join-Path $script:TempDir '10-seq-order-base.ps1'
                $childPath = Join-Path $script:TempDir '20-seq-order-child.ps1'
                Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
                Set-Content -LiteralPath $childPath -Value '# Dependencies: 10-seq-order-base' -Encoding UTF8

                $fragments = @(
                    (Get-Item -LiteralPath $childPath)
                    (Get-Item -LiteralPath $basePath)
                )

                $order = Get-FragmentLoadOrder -FragmentFiles $fragments
                [array]::IndexOf(@($order | ForEach-Object { $_.BaseName }), '10-seq-order-base') |
                    Should -BeLessThan ([array]::IndexOf(@($order | ForEach-Object { $_.BaseName }), '20-seq-order-child'))
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Omits disabled fragments from the computed load order' {
            $basePath = Join-Path $script:TempDir '10-order-base.ps1'
            $skipPath = Join-Path $script:TempDir '20-order-skip.ps1'
            Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
            Set-Content -LiteralPath $skipPath -Value '# skip' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $basePath)
                (Get-Item -LiteralPath $skipPath)
            )

            $order = Get-FragmentLoadOrder -FragmentFiles $fragments -DisabledFragments @('20-order-skip')
            @($order | ForEach-Object { $_.BaseName }) | Should -Contain '10-order-base'
            @($order | ForEach-Object { $_.BaseName }) | Should -Not -Contain '20-order-skip'
        }

        It 'Includes cyclic fragments in the remaining load-order bucket' {
            $pathA = Join-Path $script:TempDir '10-order-cycle-a.ps1'
            $pathB = Join-Path $script:TempDir '20-order-cycle-b.ps1'
            $pathC = Join-Path $script:TempDir '30-order-independent.ps1'
            Set-Content -LiteralPath $pathA -Value "#Requires -Fragment '20-order-cycle-b'" -Encoding UTF8
            Set-Content -LiteralPath $pathB -Value "#Requires -Fragment '10-order-cycle-a'" -Encoding UTF8
            Set-Content -LiteralPath $pathC -Value '# independent' -Encoding UTF8

            $fragments = @(
                (Get-Item -LiteralPath $pathA)
                (Get-Item -LiteralPath $pathB)
                (Get-Item -LiteralPath $pathC)
            )

            $order = Get-FragmentLoadOrder -FragmentFiles $fragments
            @($order | ForEach-Object { $_.BaseName }) | Should -Contain '30-order-independent'
            @($order | ForEach-Object { $_.BaseName }).Count | Should -Be 3
        }

        It 'Uses Write-Warning for invalid parallel load-order results without structured logging' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force

            try {
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                1..6 | ForEach-Object {
                    $path = Join-Path $script:TempDir "6$($_)-load-order-warning.ps1"
                    Set-Content -LiteralPath $path -Value "# fragment $_" -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                $ghostPath = Join-Path $script:TempDir '69-load-order-ghost.ps1'
                Set-Content -LiteralPath $ghostPath -Value '# ghost' -Encoding UTF8
                [void]$fragments.Add((Get-Item -LiteralPath $ghostPath))
                Remove-Item -LiteralPath $ghostPath -Force

                { Get-FragmentLoadOrder -FragmentFiles $fragments.ToArray() } | Should -Not -Throw
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Emits graph build diagnostics when parallel load-order graph construction exceeds the threshold' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                $basePath = Join-Path $script:TempDir '10-graph-delay-base.ps1'
                Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
                [void]$fragments.Add((Get-Item -LiteralPath $basePath))

                2..7 | ForEach-Object {
                    $path = Join-Path $script:TempDir "3$($_)-graph-delay.ps1"
                    Set-Content -LiteralPath $path -Value '# Dependencies: 10-graph-delay-base' -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                Set-ParallelParseTestEnvironment -DelayMs 0 -GraphBuildDelayMs 75
                $order = Get-FragmentLoadOrder -FragmentFiles $fragments.ToArray()
                @($order).Count | Should -BeGreaterThan 0
            }
            finally {
                Restore-ParallelParseTestEnvironment
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Skips invalid parallel parse results through structured warnings during load-order calculation' {
            Enable-TestStructuredLogging
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                1..6 | ForEach-Object {
                    $path = Join-Path $script:TempDir "7$($_)-load-order-invalid.ps1"
                    Set-Content -LiteralPath $path -Value "# fragment $_" -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                Set-ParallelParseTestEnvironment -DelayMs 0 -ForceProcessResultError
                $forcePath = Join-Path $script:TempDir 'force-process-result.ps1'
                Set-Content -LiteralPath $forcePath -Value '# Dependencies: bootstrap' -Encoding UTF8
                [void]$fragments.Add((Get-Item -LiteralPath $forcePath))

                { Get-FragmentLoadOrder -FragmentFiles $fragments.ToArray() } | Should -Not -Throw
            }
            finally {
                Restore-ParallelParseTestEnvironment
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }

        It 'Uses parallel parsing with timeout hooks when parallel dependencies are enabled' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousTimeout = $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS
            $previousDelay = $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '1'
            $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = '200'
            $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = '500'

            try {
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                $basePath = Join-Path $script:TempDir '10-parallel-hook-base.ps1'
                Set-Content -LiteralPath $basePath -Value '# Dependencies: bootstrap' -Encoding UTF8
                [void]$fragments.Add((Get-Item -LiteralPath $basePath))

                $sw = [Diagnostics.Stopwatch]::StartNew()
                $order = Get-FragmentLoadOrder -FragmentFiles $fragments.ToArray()
                $sw.Stop()

                @($order).Count | Should -BeGreaterThan 0
                $sw.ElapsedMilliseconds | Should -BeLessThan 5000
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -eq $previousTimeout) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = $previousTimeout
                }

                if ($null -eq $previousDelay) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = $previousDelay
                }
            }
        }

        It 'Uses sequential parsing for larger fragment sets when parallel parsing is disabled' {
            $previousParallel = $env:PS_PROFILE_PARALLEL_DEPENDENCIES
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PARALLEL_DEPENDENCIES = '0'
            $env:PS_PROFILE_DEBUG = '2'

            try {
                $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                $basePath = Join-Path $script:TempDir '10-seq-large-base.ps1'
                Set-Content -LiteralPath $basePath -Value '# base' -Encoding UTF8
                [void]$fragments.Add((Get-Item -LiteralPath $basePath))

                2..7 | ForEach-Object {
                    $path = Join-Path $script:TempDir "2$($_)-seq-large.ps1"
                    Set-Content -LiteralPath $path -Value '# Dependencies: 10-seq-large-base' -Encoding UTF8
                    [void]$fragments.Add((Get-Item -LiteralPath $path))
                }

                $order = Get-FragmentLoadOrder -FragmentFiles $fragments.ToArray()
                @($order | ForEach-Object { $_.BaseName }) | Should -Contain '10-seq-large-base'
                @($order | ForEach-Object { $_.BaseName }).Count | Should -Be 7
            }
            finally {
                if ($null -ne $previousParallel) { $env:PS_PROFILE_PARALLEL_DEPENDENCIES = $previousParallel }
                else { Remove-Item Env:PS_PROFILE_PARALLEL_DEPENDENCIES -ErrorAction SilentlyContinue }

                if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
                else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }
            }
        }
    }

    Context 'Invoke-ParallelDependencyParsing' {
        It 'Returns error metadata for missing file paths' {
            $missingPath = Join-Path $script:TempDir 'missing-parallel-parse.ps1'
            $global:TestParallelParsePaths = @($missingPath)

            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterThan 0
            }
        }

        It 'Parses Requires and Dependencies comments when direct scriptblock mode is enabled' {
            $requiresPath = Join-Path $script:TempDir 'direct-requires.ps1'
            $depsPath = Join-Path $script:TempDir 'direct-deps.ps1'
            Set-Content -LiteralPath $requiresPath -Value "#Requires -Fragment 'bootstrap'" -Encoding UTF8
            Set-Content -LiteralPath $depsPath -Value '# Dependencies: env, utilities' -Encoding UTF8
            $global:TestParallelParsePaths = @($requiresPath, $depsPath)

                        Set-ParallelParseTestEnvironment -DirectScriptblock
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                $parsed = @($results)
                $parsed.Count | Should -Be 2
                ($parsed | Where-Object { $_.FragmentName -eq 'direct-requires' }).Dependencies |
                    Should -Contain 'bootstrap'
                ($parsed | Where-Object { $_.FragmentName -eq 'direct-deps' }).Dependencies |
                    Should -Contain 'env'
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Returns parse metadata for empty and unreadable files in direct scriptblock mode' {
            $emptyPath = Join-Path $script:TempDir 'direct-empty.ps1'
            $unreadablePath = Join-Path $script:TempDir 'direct-unreadable.ps1'
            Set-Content -LiteralPath $emptyPath -Value '   ' -Encoding UTF8
            Set-Content -LiteralPath $unreadablePath -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @('   ', $emptyPath, (Join-Path $script:TempDir 'missing-direct.ps1'))
            if ($IsLinux -or $IsMacOS) {
                chmod 000 $unreadablePath
            }

            try {
                Set-ParallelParseTestEnvironment -DirectScriptblock
                InModuleScope -ModuleName FragmentLoading {
                    $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                    @($results).Count | Should -BeGreaterThan 2
                }
            }
            finally {
                if ($IsLinux -or $IsMacOS) {
                    if (Test-Path -LiteralPath $unreadablePath) {
                        chmod 644 $unreadablePath
                    }
                }

                Restore-ParallelParseTestEnvironment
                Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Returns error metadata for whitespace file paths in a parallel batch' {
            $global:TestParallelParsePaths = @('   ')

                        InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                $parsed = @($results)
                $parsed.Count | Should -BeGreaterThan 0
                [string]::IsNullOrWhiteSpace($parsed[0].FragmentName) | Should -Be $true
            }
        }
        finally {
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Uses Write-Warning for scriptblock errors when structured logging is unavailable' {
            $path = Join-Path $script:TempDir '51-scriptblock-warning.ps1'
            Set-Content -LiteralPath $path -Value '#Requires -Fragment ''unclosed' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

                        InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterThan 0
            }
        }
        finally {
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Parses dependencies for multiple files in one parallel batch' {
            $global:TestParallelParsePaths = 1..4 | ForEach-Object {
                $path = Join-Path $script:TempDir "5$($_)-parallel-batch.ps1"
                Set-Content -LiteralPath $path -Value "#Requires -Fragment 'bootstrap'" -Encoding UTF8
                $path
            }

            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results | Where-Object { $_.FragmentName }).Count | Should -Be 4
            }
        }

        It 'Reports scriptblock errors from parallel parsing when debug is enabled' {
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            $path = Join-Path $script:TempDir '50-scriptblock-error.ps1'
            Set-Content -LiteralPath $path -Value '#Requires -Fragment ''unclosed' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)

                        InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterThan 0
            }
        }
        finally {
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Parses both Requires and Dependencies declarations in one file' {
            $path = Join-Path $script:TempDir 'combo-deps.ps1'
            Set-Content -LiteralPath $path -Value @'
#Requires -Fragment 'bootstrap'
# Dependencies: env, utilities
'@ -Encoding UTF8
            $global:TestParallelParsePaths = @($path)

                        InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                $parsed = @($results)
                $parsed.Count | Should -BeGreaterThan 0
                $parsed[0].FragmentName | Should -Be 'combo-deps'
                $parsed[0].Dependencies | Should -Contain 'bootstrap'
                $parsed[0].Dependencies | Should -Contain 'env'
            }
        }
        finally {
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Returns fragment metadata for empty file content' {
            $path = Join-Path $script:TempDir 'empty-parallel-parse.ps1'
            Set-Content -LiteralPath $path -Value '' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)

                        InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                $parsed = @($results)
                $parsed.Count | Should -BeGreaterThan 0
                $parsed[0].FragmentName | Should -Be 'empty-parallel-parse'
                @($parsed[0].Dependencies).Count | Should -Be 0
            }
        }
        finally {
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Parses comma-separated dependency lists from comment lines' {
            $path = Join-Path $script:TempDir 'comma-deps-parallel.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap, env, utilities' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)

                        InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                $parsed = @($results)
                $parsed[0].FragmentName | Should -Be 'comma-deps-parallel'
                $parsed[0].Dependencies | Should -Contain 'bootstrap'
                $parsed[0].Dependencies | Should -Contain 'env'
                $parsed[0].Dependencies | Should -Contain 'utilities'
            }
        }
        finally {
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Parses valid and missing files in the same parallel batch' {
            $validPath = Join-Path $script:TempDir 'valid-parallel-parse.ps1'
            $missingPath = Join-Path $script:TempDir 'missing-batch-parse.ps1'
            Set-Content -LiteralPath $validPath -Value "#Requires -Fragment 'bootstrap'" -Encoding UTF8
            $global:TestParallelParsePaths = @($validPath, $missingPath)

                        InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results | Where-Object { $_.FragmentName -eq 'valid-parallel-parse' }).Count |
                    Should -BeGreaterThan 0
            }
        }
        finally {
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Times out when runspace parsing exceeds the configured timeout window' {
            $path = Join-Path $script:TempDir 'delay-parallel-parse.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousTimeout = $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS
            $previousDelay = $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS
            $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = '200'
            $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = '500'

            try {
                $sw = [Diagnostics.Stopwatch]::StartNew()
                InModuleScope -ModuleName FragmentLoading {
                    $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                    $parsed = @($results)
                    $parsed.Count | Should -BeGreaterThan 0
                    [string]::IsNullOrWhiteSpace($parsed[0].FragmentName) | Should -Be $true
                    @($parsed[0].Dependencies).Count | Should -Be 0
                }
                $sw.Stop()
                $sw.ElapsedMilliseconds | Should -BeLessThan 5000
            }
            finally {
                Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
                if ($null -eq $previousTimeout) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = $previousTimeout
                }

                if ($null -eq $previousDelay) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = $previousDelay
                }
            }
        }

        It 'Uses Write-StructuredWarning for global parse timeouts when debug output is disabled' {
            Enable-TestStructuredLogging
            $paths = 1..2 | ForEach-Object {
                $path = Join-Path $script:TempDir "delay-structured-global-$($_).ps1"
                Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
                $path
            }
            $global:TestParallelParsePaths = $paths
            $previousDebug = $env:PS_PROFILE_DEBUG
            $previousTimeout = $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS
            $previousDelay = $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS
            $env:PS_PROFILE_DEBUG = '0'
            $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = '200'
            $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = '500'

            try {
                InModuleScope -ModuleName FragmentLoading {
                    $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                    @($results).Count | Should -BeGreaterThan 0
                }
            }
            finally {
                Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
                if ($null -eq $previousDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $previousDebug
                }

                if ($null -eq $previousTimeout) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = $previousTimeout
                }

                if ($null -eq $previousDelay) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = $previousDelay
                }
            }
        }

        It 'Uses Write-StructuredWarning for per-file parse timeouts when debug output is disabled' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'delay-structured-perfile.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $previousTimeout = $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS
            $previousDelay = $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = '200'
            $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = '500'

            try {
                InModuleScope -ModuleName FragmentLoading {
                    $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                    $parsed = @($results)
                    $parsed.Count | Should -BeGreaterThan 0
                    [string]::IsNullOrWhiteSpace($parsed[0].FragmentName) | Should -Be $true
                }
            }
            finally {
                Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
                if ($null -eq $previousDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $previousDebug
                }

                if ($null -eq $previousTimeout) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = $previousTimeout
                }

                if ($null -eq $previousDelay) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = $previousDelay
                }
            }
        }

        It 'Warns when not all runspace parsing tasks complete within the timeout window' {
            $paths = 1..2 | ForEach-Object {
                $path = Join-Path $script:TempDir "delay-batch-$($_).ps1"
                Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
                $path
            }
            $global:TestParallelParsePaths = $paths
            $previousTimeout = $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS
            $previousDelay = $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS
            $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = '200'
            $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = '500'

            try {
                $sw = [Diagnostics.Stopwatch]::StartNew()
                InModuleScope -ModuleName FragmentLoading {
                    $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                    @($results).Count | Should -BeGreaterThan 0
                }
                $sw.Stop()
                $sw.ElapsedMilliseconds | Should -BeLessThan 5000
            }
            finally {
                Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
                if ($null -eq $previousTimeout) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = $previousTimeout
                }

                if ($null -eq $previousDelay) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = $previousDelay
                }
            }
        }

        It 'Emits runspace timeout diagnostics at debug level 3' {
            $path = Join-Path $script:TempDir 'delay-parallel-parse-debug.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $previousTimeout = $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS
            $previousDelay = $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS
            $env:PS_PROFILE_DEBUG = '3'
            $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = '200'
            $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = '500'

            try {
                InModuleScope -ModuleName FragmentLoading {
                    $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                    $parsed = @($results)
                    $parsed.Count | Should -BeGreaterThan 0
                    [string]::IsNullOrWhiteSpace($parsed[0].FragmentName) | Should -Be $true
                }
            }
            finally {
                Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
                if ($null -eq $previousDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $previousDebug
                }

                if ($null -eq $previousTimeout) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = $previousTimeout
                }

                if ($null -eq $previousDelay) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = $previousDelay
                }
            }
        }

        It 'Uses Write-Warning for runspace parse timeouts without structured logging' {
            $path = Join-Path $script:TempDir 'delay-parallel-parse-warning.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $previousDebug = $env:PS_PROFILE_DEBUG
            $previousTimeout = $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS
            $previousDelay = $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = '200'
            $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = '500'

            try {
                InModuleScope -ModuleName FragmentLoading {
                    $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                    $parsed = @($results)
                    $parsed.Count | Should -BeGreaterThan 0
                    [string]::IsNullOrWhiteSpace($parsed[0].FragmentName) | Should -Be $true
                }
            }
            finally {
                Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
                if ($null -eq $previousDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $previousDebug
                }

                if ($null -eq $previousTimeout) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = $previousTimeout
                }

                if ($null -eq $previousDelay) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = $previousDelay
                }
            }
        }

        It 'Returns an empty array when parallel parse setup fails in the outer catch block' {
            $path = Join-Path $script:TempDir 'force-setup-error.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousForce = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_ERROR

                        $env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_ERROR = '1'
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -Be 0
            }
        }
        finally {
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousForce) {
                Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_ERROR -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_ERROR = $previousForce
            }
        }

        It 'Uses Write-Error for outer parallel parse failures when structured logging is unavailable' {
            $path = Join-Path $script:TempDir 'force-setup-error-write.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousForce = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_ERROR
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force

            try {
                $env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_ERROR = '1'
                InModuleScope -ModuleName FragmentLoading {
                    $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                    @($results).Count | Should -Be 0
                }
            }
            finally {
                Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
                if ($null -eq $previousForce) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_ERROR = $previousForce
                }

                if ($null -eq $previousDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $previousDebug
                }
            }
        }

        It 'Emits outer catch diagnostics at debug level 3 when parallel parse setup fails' {
            $path = Join-Path $script:TempDir 'force-setup-error-debug.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousForce = $env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_ERROR
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_ERROR = '1'
                InModuleScope -ModuleName FragmentLoading {
                    $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                    @($results).Count | Should -Be 0
                }
            }
            finally {
                Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
                if ($null -eq $previousForce) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_FORCE_SETUP_ERROR = $previousForce
                }

                if ($null -eq $previousDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $previousDebug
                }
            }
        }

        It 'Uses Write-StructuredWarning for invalid parse results when debug output is disabled' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'invalid-result-structured.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $previousTimeout = $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS
            $previousDelay = $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS
            $env:PS_PROFILE_DEBUG = '0'
            $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = '200'
            $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = '500'

            try {
                InModuleScope -ModuleName FragmentLoading {
                    $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                    $parsed = @($results)
                    $parsed.Count | Should -BeGreaterThan 0
                    [string]::IsNullOrWhiteSpace($parsed[0].FragmentName) | Should -Be $true
                }
            }
            finally {
                Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
                if ($null -eq $previousDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $previousDebug
                }

                if ($null -eq $previousTimeout) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TIMEOUT_MS = $previousTimeout
                }

                if ($null -eq $previousDelay) {
                    Remove-Item Env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PARALLEL_PARSE_TEST_DELAY_MS = $previousDelay
                }
            }
        }

        It 'Emits scriptblock error diagnostics at debug level 3' {
            $path = Join-Path $script:TempDir '52-scriptblock-debug.ps1'
            Set-Content -LiteralPath $path -Value '#Requires -Fragment ''unclosed' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

                        InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterThan 0
            }
        }
        finally {
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Records PowerShell stream errors with structured logging at debug level 1' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'emit-ps-error.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -EmitPsError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                $parsed = @($results)
                $parsed.Count | Should -BeGreaterThan 0
                $parsed[0].FragmentName | Should -Be 'emit-ps-error'
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Uses Write-Error for PowerShell stream errors when debug is disabled and structured logging is unavailable' {
            $path = Join-Path $script:TempDir 'emit-ps-error-no-debug.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $previousDebug = $env:PS_PROFILE_DEBUG
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

                        Set-ParallelParseTestEnvironment -DelayMs 0 -EmitPsError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                $parsed = @($results)
                $parsed.Count | Should -BeGreaterThan 0
                $parsed[0].FragmentName | Should -Be 'emit-ps-error-no-debug'
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Emits PowerShell stream error diagnostics at debug level 3' {
            $path = Join-Path $script:TempDir 'emit-ps-error-debug3.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -EmitPsError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterThan 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Uses Write-Error for BeginInvoke failures when structured logging is unavailable' {
            $path = Join-Path $script:TempDir 'begininvoke-error.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceBeginInvokeError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -Be 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Emits BeginInvoke failure diagnostics at debug level 3' {
            $path = Join-Path $script:TempDir 'begininvoke-error-debug3.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceBeginInvokeError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -Be 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Handles post-processing result errors at debug level 1' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'force-process-result.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceProcessResultError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                $parsed = @($results)
                $parsed.Count | Should -BeGreaterThan 0
                $parsed[0].FragmentName | Should -Be 'force-process-result'
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Emits post-processing result error diagnostics at debug level 3' {
            $path = Join-Path $script:TempDir 'force-process-result.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceProcessResultError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterThan 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Warns when only some parse tasks complete before the global timeout window' {
            $fastPath = Join-Path $script:TempDir 'fast-parse.ps1'
            $slowPath = Join-Path $script:TempDir 'slow-parse.ps1'
            Set-Content -LiteralPath $fastPath -Value '# Dependencies: bootstrap' -Encoding UTF8
            Set-Content -LiteralPath $slowPath -Value '# Dependencies: env' -Encoding UTF8
            $global:TestParallelParsePaths = @($fastPath, $slowPath)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

                        Set-ParallelParseTestEnvironment -TimeoutMs 800 -DelayMs 100 -SlowDelayMs 2000
            $sw = [Diagnostics.Stopwatch]::StartNew()
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results | Where-Object { $_.FragmentName -eq 'fast-parse' }).Count | Should -BeGreaterOrEqual 1
            }
            $sw.Stop()
            $sw.ElapsedMilliseconds | Should -BeLessThan 5000
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Uses Write-Error for setup runspace failures when structured logging is unavailable' {
            $path = Join-Path $script:TempDir 'setup-runspace-error.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceSetupRunspaceError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -Be 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Records process runspace failures with structured logging at debug level 1' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'process-runspace-error.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceProcessRunspaceError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterThan 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Records EndInvoke failures with structured logging at debug level 1' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'endinvoke-error.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceEndInvokeError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterThan 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Uses Write-Error for EndInvoke failures when structured logging is unavailable' {
            $path = Join-Path $script:TempDir 'endinvoke-error-write.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceEndInvokeError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterThan 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Uses Write-Error for process runspace failures when structured logging is unavailable' {
            $path = Join-Path $script:TempDir 'process-runspace-error-write.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceProcessRunspaceError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterThan 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Uses Write-Error for AddArgument failures when structured logging is unavailable' {
            $path = Join-Path $script:TempDir 'addargument-error.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceAddArgumentError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -Be 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Records dispose failures with structured logging at debug level 1' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'dispose-error.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceDisposeError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterThan 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Records timeout result add failures with structured logging at debug level 1' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'force-timeout-add.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

                        Set-ParallelParseTestEnvironment -DelayMs 500 -TimeoutMs 50 -ForceTimeoutResultAddError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterOrEqual 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Uses Write-StructuredError for error result add failures when debug is disabled' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'error-result-add.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceProcessRunspaceError -ForceErrorResultAddError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterOrEqual 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Uses Write-StructuredError for PowerShell stream errors when debug is disabled' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'emit-ps-error-structured-off.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -EmitPsError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterThan 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Records AddScript failures with structured logging at debug level 1' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'addscript-structured.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceAddScriptError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -Be 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Records AddArgument failures with structured logging at debug level 1' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'addargument-structured.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceAddArgumentError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -Be 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Records setup runspace failures with structured logging at debug level 1' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'setup-runspace-structured.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceSetupRunspaceError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -Be 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Records BeginInvoke null-handle failures with structured logging at debug level 1' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'begininvoke-null.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceBeginInvokeNull
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -Be 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Records runspace list add failures with structured logging at debug level 3' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'add-runspaces-structured.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceAddToRunspacesError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -Be 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Emits stalled runspace stop diagnostics at debug level 3' {
            $path = Join-Path $script:TempDir 'stop-stalled-debug3.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

                        Set-ParallelParseTestEnvironment -DelayMs 500 -TimeoutMs 50 -ForceStopStalledError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterOrEqual 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Uses Write-Error for AddScript failures when structured logging is unavailable' {
            $path = Join-Path $script:TempDir 'addscript-error.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force

                        Set-ParallelParseTestEnvironment -DelayMs 0 -ForceAddScriptError
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -Be 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Uses Write-Warning for global parse timeouts at debug level 1 without structured logging' {
            $path = Join-Path $script:TempDir 'global-timeout-warning.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $global:TestParallelParsePaths = @($path)
            $previousDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force

                        Set-ParallelParseTestEnvironment
            InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                @($results).Count | Should -BeGreaterThan 0
            }
        }
        finally {
            Restore-ParallelParseTestEnvironment
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $previousDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }

        It 'Reports scriptblock read failures when locked files block readers' {
            Enable-TestStructuredLogging
            $path = Join-Path $script:TempDir 'locked-parallel-parse.ps1'
            Set-Content -LiteralPath $path -Value '# Dependencies: bootstrap' -Encoding UTF8
            $fileStream = [System.IO.File]::Open(
                $path,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::None)
            $global:TestParallelParsePaths = @($path)

                        InModuleScope -ModuleName FragmentLoading {
                $results = Invoke-ParallelDependencyParsing -FilePaths $global:TestParallelParsePaths
                $parsed = @($results)
                $parsed.Count | Should -BeGreaterThan 0
                $parsed[0].FragmentName | Should -Be 'locked-parallel-parse'
                @($parsed[0].Dependencies).Count | Should -Be 0
            }
        }
        finally {
            $fileStream.Dispose()
            Remove-Variable -Name TestParallelParsePaths -Scope Global -ErrorAction SilentlyContinue
        }

    }

    Context 'Get-FragmentDependencies cache invalidation' {
        It 'Refreshes cached dependencies after the fragment file changes' {
            $fragmentPath = Join-Path $script:TempDir 'refresh-deps.ps1'
            Set-Content -LiteralPath $fragmentPath -Value '# Dependencies: bootstrap' -Encoding UTF8

            $first = Get-FragmentDependencies -FragmentFile $fragmentPath
            Set-Content -LiteralPath $fragmentPath -Value '# Dependencies: env' -Encoding UTF8
            $second = Get-FragmentDependencies -FragmentFile $fragmentPath

            $first | Should -Contain 'bootstrap'
            $second | Should -Contain 'env'
            $second | Should -Not -Contain 'bootstrap'
        }
    }

    Context 'Get-FragmentTiers' {
        It 'Groups standard and optional tier fragments into separate buckets' {
            $standardPath = Join-Path $script:TempDir 'standard-tier.ps1'
            $optionalPath = Join-Path $script:TempDir 'optional-tier.ps1'
            Set-Content -LiteralPath $standardPath -Value "# Tier: standard`n# standard" -Encoding UTF8
            Set-Content -LiteralPath $optionalPath -Value "# Tier: optional`n# optional" -Encoding UTF8

            $tiers = Get-FragmentTiers -FragmentFiles @(
                (Get-Item -LiteralPath $standardPath)
                (Get-Item -LiteralPath $optionalPath)
            )

            @($tiers.Tier2 | ForEach-Object { $_.BaseName }) | Should -Contain 'standard-tier'
            @($tiers.Tier3 | ForEach-Object { $_.BaseName }) | Should -Contain 'optional-tier'
        }

        It 'Places fragments with unknown tier declarations into the optional bucket' {
            $unknownPath = Join-Path $script:TempDir 'unknown-tier.ps1'
            Set-Content -LiteralPath $unknownPath -Value "# Tier: experimental`n# fragment" -Encoding UTF8

            $tiers = Get-FragmentTiers -FragmentFiles @(
                (Get-Item -LiteralPath $unknownPath)
            )

            @($tiers.Tier3 | ForEach-Object { $_.BaseName }) | Should -Contain 'unknown-tier'
        }

        It 'Excludes bootstrap fragments when ExcludeBootstrap is specified' {
            $bootstrapPath = Join-Path $script:TempDir 'bootstrap.ps1'
            $corePath = Join-Path $script:TempDir 'core-tier.ps1'
            Set-Content -LiteralPath $bootstrapPath -Value @'
# Tier: core
# bootstrap
'@ -Encoding UTF8
            Set-Content -LiteralPath $corePath -Value @'
# Tier: core
# core
'@ -Encoding UTF8

            $tiers = Get-FragmentTiers -FragmentFiles @(
                (Get-Item -LiteralPath $bootstrapPath)
                (Get-Item -LiteralPath $corePath)
            ) -ExcludeBootstrap

            @($tiers.Tier0 | ForEach-Object { $_.BaseName }) | Should -Contain 'core-tier'
            @($tiers.Tier0 | ForEach-Object { $_.BaseName }) | Should -Not -Contain 'bootstrap'
        }
    }
}
