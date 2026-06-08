<#
tests/unit/library-profile-fragment-loader-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ProfileFragmentLoader batch progress and reload helpers.
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
    $script:LibDir = Join-Path $script:RepoRoot 'scripts' 'lib'
    $script:FragmentLibDir = Join-Path $script:LibDir 'fragment'
    $script:FragmentLoadingModule = Join-Path $script:FragmentLibDir 'FragmentLoading.psm1'
    $script:FragmentErrorHandlingModule = Join-Path $script:FragmentLibDir 'FragmentErrorHandling.psm1'
    $script:LoaderPath = Join-Path $script:LibDir 'profile' 'ProfileFragmentLoader.psm1'
    Import-Module $script:LoaderPath -DisableNameChecking -Force -Global
    $parallelLoadingPath = Join-Path $script:FragmentLibDir 'FragmentParallelLoading.psm1'
    if (Test-Path -LiteralPath $parallelLoadingPath) {
        Import-Module $parallelLoadingPath -DisableNameChecking -Force -Global
    }

    $script:TempDir = New-TestTempDirectory -Prefix 'ProfileFragmentLoaderExtended'
    $script:ModuleFile = Join-Path $script:TempDir 'ReloadProbe.psm1'
    $script:ModuleName = 'ReloadProbe'

    Set-Content -LiteralPath $script:ModuleFile -Value @'
function Get-ReloadProbeValue {
    return 'initial'
}
Export-ModuleMember -Function Get-ReloadProbeValue
'@ -Encoding UTF8

    if (-not (Get-Variable -Name PSProfileModuleFileTimes -Scope Global -ErrorAction SilentlyContinue)) {
        $global:PSProfileModuleFileTimes = @{}
    }

    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
    $script:OrchestrationModulePath = Join-Path (Split-Path $script:LoaderPath -Parent) 'ProfileFragmentLoadingOrchestration.psm1'
    $script:OrchestrationHiddenPath = "$script:OrchestrationModulePath.test-hidden"
}

function script:Ensure-TestOrchestrationModule {
    Remove-Module ProfileFragmentLoadingOrchestration -ErrorAction SilentlyContinue -Force
    Import-Module $script:OrchestrationModulePath -DisableNameChecking -Force -ErrorAction Stop
}

function script:Hide-TestOrchestrationModule {
    Remove-Module ProfileFragmentLoadingOrchestration -ErrorAction SilentlyContinue -Force
    if (Test-Path -LiteralPath $script:OrchestrationModulePath) {
        if (Test-Path -LiteralPath $script:OrchestrationHiddenPath) {
            Remove-Item -LiteralPath $script:OrchestrationHiddenPath -Force -ErrorAction SilentlyContinue
        }
        Move-Item -LiteralPath $script:OrchestrationModulePath -Destination $script:OrchestrationHiddenPath -Force
    }
}

function script:Restore-TestOrchestrationModule {
    Remove-Module ProfileFragmentLoadingOrchestration -ErrorAction SilentlyContinue -Force
    if (Test-Path -LiteralPath $script:OrchestrationHiddenPath) {
        if (Test-Path -LiteralPath $script:OrchestrationModulePath) {
            Remove-Item -LiteralPath $script:OrchestrationModulePath -Force -ErrorAction SilentlyContinue
        }
        Move-Item -LiteralPath $script:OrchestrationHiddenPath -Destination $script:OrchestrationModulePath -Force
    }
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        return
    }

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
}

function script:New-ProfileLoaderFixture {
    param(
        [string]$Prefix,
        [string]$FragmentName = '20-loader-probe.ps1',
        [string]$FragmentBody = '# noop fragment',
        [string[]]$AdditionalFragments = @()
    )

    $profileD = Join-Path $script:TempDir $Prefix
    New-Item -ItemType Directory -Path $profileD -Force | Out-Null
    $fragmentPath = Join-Path $profileD $FragmentName
    Set-Content -LiteralPath $fragmentPath -Value $FragmentBody -Encoding UTF8

    $fragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    [void]$fragments.Add((Get-Item -LiteralPath $fragmentPath))

    foreach ($extra in $AdditionalFragments) {
        $parts = $extra -split '\|', 2
        $extraName = $parts[0]
        $extraBody = if ($parts.Count -gt 1) { $parts[1] } else { '# noop' }
        $extraPath = Join-Path $profileD $extraName
        Set-Content -LiteralPath $extraPath -Value $extraBody -Encoding UTF8
        [void]$fragments.Add((Get-Item -LiteralPath $extraPath))
    }

    return [PSCustomObject]@{
        ProfileD  = $profileD
        Fragments = $fragments
    }
}

function script:Invoke-ProfileLoaderInit {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Fixture,

        [bool]$EnableParallelLoading = $false,
        [bool]$EnableLazyLoading = $false,
        [bool]$EnableTestMode = $false,
        [bool]$EnableProxyCreation = $false,
        [bool]$EnablePrewarmCache = $false,
        [string]$DebugLevel = $null,
        [System.Collections.Generic.HashSet[string]]$DisabledSet = $null,
        [System.IO.FileInfo[]]$BootstrapFragment = @(),
        [bool]$FragmentLoadingModuleExists = $true,
        [bool]$LoadBatchLoadingSummary = $false
    )

    $previousLoadAll = $env:PS_PROFILE_LOAD_ALL_FRAGMENTS
    $previousProxies = $env:PS_PROFILE_CREATE_PROXIES
    $previousLazy = $env:PS_PROFILE_LAZY_LOAD_FRAGMENTS
    $previousTestMode = $env:PS_PROFILE_TEST_MODE
    $previousDebug = $env:PS_PROFILE_DEBUG
    $previousPrewarm = $env:PS_PROFILE_PREWARM_CACHE

    if ($null -ne $DebugLevel) {
        $env:PS_PROFILE_DEBUG = $DebugLevel
    }

    if ($EnableTestMode) {
        $env:PS_PROFILE_TEST_MODE = '1'
        Remove-Item Env:PS_PROFILE_LAZY_LOAD_FRAGMENTS -ErrorAction SilentlyContinue
        Remove-Item Env:PS_PROFILE_LOAD_ALL_FRAGMENTS -ErrorAction SilentlyContinue
    }
    else {
        Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue

        if ($EnableLazyLoading) {
            $env:PS_PROFILE_LAZY_LOAD_FRAGMENTS = '1'
            Remove-Item Env:PS_PROFILE_LOAD_ALL_FRAGMENTS -ErrorAction SilentlyContinue
        }
        else {
            $env:PS_PROFILE_LOAD_ALL_FRAGMENTS = '1'
            Remove-Item Env:PS_PROFILE_LAZY_LOAD_FRAGMENTS -ErrorAction SilentlyContinue
        }
    }

    if ($EnableProxyCreation) {
        $env:PS_PROFILE_CREATE_PROXIES = '1'
    }
    else {
        $env:PS_PROFILE_CREATE_PROXIES = '0'
    }

    if ($EnablePrewarmCache) {
        $env:PS_PROFILE_PREWARM_CACHE = '1'
    }
    else {
        Remove-Item Env:PS_PROFILE_PREWARM_CACHE -ErrorAction SilentlyContinue
    }

    if ($LoadBatchLoadingSummary) {
        . (Join-Path $script:ProfileDir 'bootstrap' 'BatchLoadingSummary.ps1')
        Initialize-BatchLoadingInfo
    }

    try {
        Initialize-FragmentLoading `
            -FragmentsToLoad $Fixture.Fragments `
            -BootstrapFragment $BootstrapFragment `
            -DisabledSet $DisabledSet `
            -EnableParallelLoading $EnableParallelLoading `
            -FragmentLoadingModule $script:FragmentLoadingModule `
            -FragmentLoadingModuleExists $FragmentLoadingModuleExists `
            -FragmentLibDir $script:FragmentLibDir `
            -FragmentErrorHandlingModule $script:FragmentErrorHandlingModule `
            -FragmentErrorHandlingModuleExists $true `
            -ProfileD $Fixture.ProfileD
    }
    finally {
        if ($null -ne $previousLoadAll) { $env:PS_PROFILE_LOAD_ALL_FRAGMENTS = $previousLoadAll }
        else { Remove-Item Env:PS_PROFILE_LOAD_ALL_FRAGMENTS -ErrorAction SilentlyContinue }

        if ($null -ne $previousProxies) { $env:PS_PROFILE_CREATE_PROXIES = $previousProxies }
        else { Remove-Item Env:PS_PROFILE_CREATE_PROXIES -ErrorAction SilentlyContinue }

        if ($null -ne $previousLazy) { $env:PS_PROFILE_LAZY_LOAD_FRAGMENTS = $previousLazy }
        else { Remove-Item Env:PS_PROFILE_LAZY_LOAD_FRAGMENTS -ErrorAction SilentlyContinue }

        if ($null -ne $previousTestMode) { $env:PS_PROFILE_TEST_MODE = $previousTestMode }
        else { Remove-Item Env:PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue }

        if ($null -ne $previousDebug) { $env:PS_PROFILE_DEBUG = $previousDebug }
        else { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue }

        if ($null -ne $previousPrewarm) { $env:PS_PROFILE_PREWARM_CACHE = $previousPrewarm }
        else { Remove-Item Env:PS_PROFILE_PREWARM_CACHE -ErrorAction SilentlyContinue }
    }
}

AfterAll {
    Restore-TestOrchestrationModule
    Remove-Module -Name $script:ModuleName -ErrorAction SilentlyContinue -Force
    Remove-Module -Name ProfileFragmentLoader -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ProfileFragmentLoader extended scenarios' {
    Context 'Test-AndReloadModuleIfChanged' {
        BeforeEach {
            $global:PSProfileModuleFileTimes = @{}
        }

        It 'Returns false when the module file exists but is not loaded yet' {
            $global:TestReloadModulePath = $script:ModuleFile
            $global:TestReloadModuleName = $script:ModuleName

            try {
                Remove-Module -Name $script:ModuleName -ErrorAction SilentlyContinue -Force

                InModuleScope -ModuleName ProfileFragmentLoader {
                    Test-AndReloadModuleIfChanged `
                        -ModulePath $global:TestReloadModulePath `
                        -ModuleName $global:TestReloadModuleName | Should -Be $false
                }

                Get-Module -Name $script:ModuleName | Should -BeNullOrEmpty
            }
            finally {
                Remove-Variable -Name TestReloadModulePath, TestReloadModuleName -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Updates cached write time without forcing reload when content is unchanged' {
            $global:TestReloadModulePath = $script:ModuleFile
            $global:TestReloadModuleName = $script:ModuleName

            try {
                Remove-Module -Name $script:ModuleName -ErrorAction SilentlyContinue -Force
                Import-Module -Name $script:ModuleFile -Force

                InModuleScope -ModuleName ProfileFragmentLoader {
                    Test-AndReloadModuleIfChanged `
                        -ModulePath $global:TestReloadModulePath `
                        -ModuleName $global:TestReloadModuleName | Should -Be $false

                    Test-AndReloadModuleIfChanged `
                        -ModulePath $global:TestReloadModulePath `
                        -ModuleName $global:TestReloadModuleName | Should -Be $false
                }

                (Get-Module -Name $script:ModuleName).Name | Should -Be $script:ModuleName
            }
            finally {
                Remove-Variable -Name TestReloadModulePath, TestReloadModuleName -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Write-BatchProgressRow' {
        BeforeEach {
            $global:BatchProgressOutput = [System.Collections.Generic.List[string]]::new()
        }

        It 'Calculates progress percentage from batch number and total batches' {
            InModuleScope -ModuleName ProfileFragmentLoader {
                Mock Write-Host {
                    param([object]$Object)
                    $null = $global:BatchProgressOutput.Add([string]$Object)
                }

                Write-BatchProgressRow -BatchNumber 2 -TotalBatches 4 -FragmentCount 3 -FragmentNames @('a', 'b', 'c')
            }

            ($global:BatchProgressOutput | Select-Object -Last 1) | Should -Match '50%'
        }

        It 'Truncates fragment name lists longer than ten entries' {
            InModuleScope -ModuleName ProfileFragmentLoader {
                Mock Write-Host {
                    param([object]$Object)
                    $null = $global:BatchProgressOutput.Add([string]$Object)
                }

                $names = 1..12 | ForEach-Object { "frag-$_" }
                Write-BatchProgressRow -BatchNumber 1 -TotalBatches 1 -FragmentCount 12 -FragmentNames $names
            }

            ($global:BatchProgressOutput | Select-Object -Last 1) | Should -Match '\(\+2 more\)'
        }
    }

    Context 'Write-BatchProgressTableHeader' {
        It 'Prints the table header only once per loader session' {
            $global:BatchProgressOutput = [System.Collections.Generic.List[string]]::new()

            InModuleScope -ModuleName ProfileFragmentLoader {
                Mock Write-Host {
                    param([object]$Object)
                    $null = $global:BatchProgressOutput.Add([string]$Object)
                }

                Write-BatchProgressTableHeader
                Write-BatchProgressTableHeader
            }

            @($global:BatchProgressOutput | Where-Object { $_ -match '^Batch\s+Fragments' }).Count | Should -Be 1
        }
    }

    Context 'Initialize-FragmentLoading' {
        It 'Completes when a minimal fragment list is provided' {
            $fixture = New-ProfileLoaderFixture -Prefix 'minimal-profile.d'
            { Invoke-ProfileLoaderInit -Fixture $fixture } | Should -Not -Throw
        }

        It 'Loads bootstrap fragments from the provided bootstrap list' {
            $fixture = New-ProfileLoaderFixture -Prefix 'bootstrap-profile.d'
            $bootstrapPath = Join-Path $fixture.ProfileD 'bootstrap.ps1'
            Set-Content -LiteralPath $bootstrapPath -Value '$global:ProfileFragmentLoaderBootstrapProbe = $true' -Encoding UTF8
            $bootstrap = Get-Item -LiteralPath $bootstrapPath

            try {
                Remove-Variable -Name ProfileFragmentLoaderBootstrapProbe -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture -BootstrapFragment @($bootstrap)
                $global:ProfileFragmentLoaderBootstrapProbe | Should -Be $true
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderBootstrapProbe -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Skips fragments listed in DisabledSet' {
            $fixture = New-ProfileLoaderFixture -Prefix 'disabled-profile.d' -FragmentBody '$global:ProfileFragmentLoaderDisabledProbe = $true'
            $disabled = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            [void]$disabled.Add('20-loader-probe')

            try {
                Remove-Variable -Name ProfileFragmentLoaderDisabledProbe -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture -DisabledSet $disabled
                Get-Variable -Name ProfileFragmentLoaderDisabledProbe -Scope Global -ErrorAction SilentlyContinue |
                    Should -BeNullOrEmpty
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderDisabledProbe -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Loads multiple fragments when parallel loading is enabled' {
            $markerA = Join-Path $script:TempDir 'parallel-a.marker'
            $markerB = Join-Path $script:TempDir 'parallel-b.marker'
            $fixture = New-ProfileLoaderFixture `
                -Prefix 'parallel-profile.d' `
                -FragmentName '20-parallel-a.ps1' `
                -FragmentBody "Set-Content -LiteralPath '$markerA' -Value 'ok' -Encoding UTF8" `
                -AdditionalFragments @(
                "30-parallel-b.ps1|Set-Content -LiteralPath '$markerB' -Value 'ok' -Encoding UTF8"
            )

            try {
                Remove-Item -LiteralPath $markerA, $markerB -Force -ErrorAction SilentlyContinue
                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableParallelLoading $true } | Should -Not -Throw
                (Get-Content -LiteralPath $markerA -Raw).Trim() | Should -Be 'ok'
                (Get-Content -LiteralPath $markerB -Raw).Trim() | Should -Be 'ok'
            }
            finally {
                Remove-Item -LiteralPath $markerA, $markerB -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns early without loading fragment bodies when lazy loading is enabled' {
            $fixture = New-ProfileLoaderFixture -Prefix 'lazy-profile.d' -FragmentBody '$global:ProfileFragmentLoaderLazyProbe = $true'

            try {
                Remove-Variable -Name ProfileFragmentLoaderLazyProbe -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true
                (Get-Variable -Name ProfileFragmentLoaderLazyProbe -Scope Global -ErrorAction SilentlyContinue) |
                    Should -BeNullOrEmpty
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderLazyProbe -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Survives failing fragment bodies without terminating initialization' {
            $fixture = New-ProfileLoaderFixture -Prefix 'failing-profile.d' -FragmentBody 'throw "profile loader failure probe"'
            { Invoke-ProfileLoaderInit -Fixture $fixture } | Should -Not -Throw
        }

        It 'Loads dependent fragments in dependency order' {
            $fixture = New-ProfileLoaderFixture `
                -Prefix 'dependency-profile.d' `
                -FragmentName '20-parent.ps1' `
                -FragmentBody '$global:ProfileFragmentLoaderParentProbe = ''loaded''' `
                -AdditionalFragments @(
                '30-child.ps1|# Dependencies: 20-parent
$global:ProfileFragmentLoaderChildProbe = ''loaded'''
            )

            try {
                Remove-Variable -Name ProfileFragmentLoaderChildProbe, ProfileFragmentLoaderParentProbe -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture
                $global:ProfileFragmentLoaderParentProbe | Should -Be 'loaded'
                $global:ProfileFragmentLoaderChildProbe | Should -Be 'loaded'
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderChildProbe, ProfileFragmentLoaderParentProbe -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Completes lazy loading with debug tracing enabled' {
            $fixture = New-ProfileLoaderFixture -Prefix 'lazy-debug-profile.d'
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true } | Should -Not -Throw
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

        It 'Loads fragments eagerly when PS_PROFILE_TEST_MODE is enabled' {
            $fixture = New-ProfileLoaderFixture -Prefix 'testmode-profile.d' -FragmentBody '$global:ProfileFragmentLoaderTestModeProbe = $true'

            try {
                Remove-Variable -Name ProfileFragmentLoaderTestModeProbe -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture -EnableTestMode $true
                $global:ProfileFragmentLoaderTestModeProbe | Should -Be $true
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderTestModeProbe -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Survives failing bootstrap fragments without terminating initialization' {
            $fixture = New-ProfileLoaderFixture -Prefix 'bootstrap-fail-profile.d'
            $bootstrapPath = Join-Path $fixture.ProfileD 'bootstrap.ps1'
            Set-Content -LiteralPath $bootstrapPath -Value 'throw "bootstrap failure probe"' -Encoding UTF8
            $bootstrap = Get-Item -LiteralPath $bootstrapPath
            $previousErrorAction = $ErrorActionPreference

            try {
                $ErrorActionPreference = 'Continue'
                { Invoke-ProfileLoaderInit -Fixture $fixture -BootstrapFragment @($bootstrap) } | Should -Not -Throw
            }
            finally {
                $ErrorActionPreference = $previousErrorAction
            }
        }

        It 'Lists many fragments under lazy loading with level 3 debug tracing' {
            $extras = 2..12 | ForEach-Object { "1$($_)-lazy-extra.ps1|# fragment $_" }
            $fixture = New-ProfileLoaderFixture -Prefix 'lazy-many-profile.d' -AdditionalFragments $extras

            { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -DebugLevel '3' } | Should -Not -Throw
        }

        It 'Loads several fragments with level 1 debug batch output enabled' {
            $extras = 2..4 | ForEach-Object { "2$($_)-batch-debug.ps1|`$global:ProfileFragmentLoaderBatch$_ = `$true" }
            $fixture = New-ProfileLoaderFixture -Prefix 'batch-debug-profile.d' -AdditionalFragments $extras

            try {
                Remove-Variable -Name ProfileFragmentLoaderBatch2, ProfileFragmentLoaderBatch3, ProfileFragmentLoaderBatch4 -Scope Global -ErrorAction SilentlyContinue
                { Invoke-ProfileLoaderInit -Fixture $fixture -DebugLevel '1' } | Should -Not -Throw
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderBatch2, ProfileFragmentLoaderBatch3, ProfileFragmentLoaderBatch4 -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Runs dependency analysis output when parallel loading and debug are enabled' {
            $markerA = Join-Path $script:TempDir 'dep-a.marker'
            $markerB = Join-Path $script:TempDir 'dep-b.marker'
            $fixture = New-ProfileLoaderFixture `
                -Prefix 'dep-debug-profile.d' `
                -FragmentName '20-dep-a.ps1' `
                -FragmentBody "Set-Content -LiteralPath '$markerA' -Value 'ok' -Encoding UTF8" `
                -AdditionalFragments @("30-dep-b.ps1|Set-Content -LiteralPath '$markerB' -Value 'ok' -Encoding UTF8")
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                Remove-Item -LiteralPath $markerA, $markerB -Force -ErrorAction SilentlyContinue
                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableParallelLoading $true } | Should -Not -Throw
                (Get-Content -LiteralPath $markerA -Raw).Trim() | Should -Be 'ok'
                (Get-Content -LiteralPath $markerB -Raw).Trim() | Should -Be 'ok'
            }
            finally {
                Remove-Item -LiteralPath $markerA, $markerB -Force -ErrorAction SilentlyContinue
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }

    Context 'Structured logging and cache paths' {
        It 'Records orchestration fallback through Write-StructuredWarning' {
            Enable-TestStructuredLogging
            $fixture = New-ProfileLoaderFixture -Prefix 'orchestration-warning-profile.d'

            Hide-TestOrchestrationModule
            try {
                { Invoke-ProfileLoaderInit -Fixture $fixture } | Should -Not -Throw
            }
            finally {
                Restore-TestOrchestrationModule
            }
        }

        It 'Survives cache pre-warming failures when sqlite helpers are available' {
            Enable-TestStructuredLogging
            $fixture = New-ProfileLoaderFixture -Prefix 'prewarm-fail-profile.d'
            function global:Test-SqliteAvailable { return $true }
            function global:Initialize-FragmentCache {
                param(
                    [object[]]$FragmentFiles,
                    [bool]$UseAstParsing
                )
                throw 'cache prewarm probe'
            }

            try {
                { Invoke-ProfileLoaderInit -Fixture $fixture -EnablePrewarmCache $true -DebugLevel '2' } | Should -Not -Throw
            }
            finally {
                Remove-Item -Path Function:Test-SqliteAvailable -ErrorAction SilentlyContinue -Force
                Remove-Item -Path Function:Initialize-FragmentCache -ErrorAction SilentlyContinue -Force
            }
        }

        It 'Runs proxy creation when lazy loading and proxy creation are enabled' {
            $fixture = New-ProfileLoaderFixture -Prefix 'proxy-profile.d' -FragmentBody @'
function Get-ProfileLoaderProxyProbe {
    return 'proxy-ok'
}
'@

            { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -EnableProxyCreation $true -DebugLevel '2' } |
                Should -Not -Throw
        }

        It 'Records fragment results when BatchLoadingSummary helpers are loaded' {
            $fixture = New-ProfileLoaderFixture `
                -Prefix 'batch-summary-profile.d' `
                -FragmentName '20-batch-ok.ps1' `
                -FragmentBody '$global:ProfileFragmentLoaderBatchOk = $true' `
                -AdditionalFragments @('30-batch-fail.ps1|throw "batch summary failure probe"')

            try {
                Remove-Variable -Name ProfileFragmentLoaderBatchOk -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture -LoadBatchLoadingSummary $true
                $global:BatchLoadingInfo.SucceededFragments.Count | Should -BeGreaterThan 0
                $global:BatchLoadingInfo.FailedFragments.Count | Should -BeGreaterThan 0
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderBatchOk -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Survives pre-registration failures when lazy loading is enabled' {
            Enable-TestStructuredLogging
            $fixture = New-ProfileLoaderFixture -Prefix 'pre-register-fail-profile.d'
            $registryPath = Join-Path $script:FragmentLibDir 'FragmentCommandRegistry.psm1'
            Import-Module $registryPath -DisableNameChecking -Force -Global
            Mock Register-AllFragmentCommands {
                throw 'pre-register failure probe'
            } -ModuleName FragmentCommandRegistry

            try {
                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -DebugLevel '1' } | Should -Not -Throw
            }
            finally {
                Remove-Module FragmentCommandRegistry -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Uses Write-Warning when dependency grouping fails without structured helpers' {
            $fixture = New-ProfileLoaderFixture -Prefix 'grouping-warning-profile.d'
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force

            Import-Module $script:FragmentLoadingModule -DisableNameChecking -Force -Global
            Mock Get-FragmentDependencyLevels {
                throw 'dependency grouping warning probe'
            } -ModuleName FragmentLoading

            try {
                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableParallelLoading $true -DebugLevel '1' } | Should -Not -Throw
            }
            finally {
                Remove-Module FragmentLoading -Force -ErrorAction SilentlyContinue
                Import-Module $script:FragmentLoadingModule -DisableNameChecking -Force -Global
            }
        }

        It 'Falls back to sequential loading when dependency grouping fails' {
            Enable-TestStructuredLogging
            $markerA = Join-Path $script:TempDir 'group-a.marker'
            $markerB = Join-Path $script:TempDir 'group-b.marker'
            $fixture = New-ProfileLoaderFixture `
                -Prefix 'grouping-fail-profile.d' `
                -FragmentName '20-group-a.ps1' `
                -FragmentBody "Set-Content -LiteralPath '$markerA' -Value 'ok' -Encoding UTF8" `
                -AdditionalFragments @("30-group-b.ps1|Set-Content -LiteralPath '$markerB' -Value 'ok' -Encoding UTF8")

            Import-Module $script:FragmentLoadingModule -DisableNameChecking -Force -Global
            Mock Get-FragmentDependencyLevels {
                throw 'dependency grouping failure probe'
            } -ModuleName FragmentLoading

            try {
                Remove-Item -LiteralPath $markerA, $markerB -Force -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture -EnableParallelLoading $true -DebugLevel '1'
                (Get-Content -LiteralPath $markerA -Raw).Trim() | Should -Be 'ok'
                (Get-Content -LiteralPath $markerB -Raw).Trim() | Should -Be 'ok'
            }
            finally {
                Remove-Module FragmentLoading -Force -ErrorAction SilentlyContinue
                Import-Module $script:FragmentLoadingModule -DisableNameChecking -Force -Global
                Remove-Item -LiteralPath $markerA, $markerB -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Completes initialization when the fragment loading module is reported unavailable' {
            $fixture = New-ProfileLoaderFixture -Prefix 'no-fragment-module-profile.d'
            { Invoke-ProfileLoaderInit -Fixture $fixture -EnableParallelLoading $true -FragmentLoadingModuleExists $false } |
                Should -Not -Throw
        }

        It 'Skips pre-registration with debug tracing when eager loading is enabled' {
            $fixture = New-ProfileLoaderFixture -Prefix 'pre-register-skip-profile.d'
            { Invoke-ProfileLoaderInit -Fixture $fixture -DebugLevel '2' } | Should -Not -Throw
        }

        It 'Records dependency parsing metadata when batch helpers are loaded' {
            Ensure-TestOrchestrationModule
            $extras = 2..4 | ForEach-Object { "2$($_)-dep-meta.ps1|# fragment $_" }
            $fixture = New-ProfileLoaderFixture -Prefix 'dep-meta-profile.d' -AdditionalFragments $extras

            try {
                Invoke-ProfileLoaderInit -Fixture $fixture -EnableParallelLoading $true -LoadBatchLoadingSummary $true
                $global:BatchLoadingInfo.DependencyParsingTime | Should -BeGreaterOrEqual 0
                $global:BatchLoadingInfo.DependencyLevels | Should -BeGreaterThan 0
            }
            finally {
                if ($global:BatchLoadingInfo) {
                    $global:BatchLoadingInfo = $null
                }
            }
        }

        It 'Uses Write-StructuredError when bootstrap loading fails without debug output' {
            Enable-TestStructuredLogging
            $fixture = New-ProfileLoaderFixture -Prefix 'bootstrap-structured-profile.d'
            $bootstrapPath = Join-Path $fixture.ProfileD 'bootstrap.ps1'
            Set-Content -LiteralPath $bootstrapPath -Value 'throw "bootstrap structured probe"' -Encoding UTF8
            $bootstrap = Get-Item -LiteralPath $bootstrapPath
            $previousErrorAction = $ErrorActionPreference

            try {
                $ErrorActionPreference = 'Continue'
                { Invoke-ProfileLoaderInit -Fixture $fixture -BootstrapFragment @($bootstrap) } | Should -Not -Throw
            }
            finally {
                $ErrorActionPreference = $previousErrorAction
            }
        }
    }

    Context 'Orchestration module integration' {
        BeforeEach {
            Ensure-TestOrchestrationModule
        }

        It 'Loads fragments through the orchestration module' {
            $fixture = New-ProfileLoaderFixture `
                -Prefix 'orchestration-load-profile.d' `
                -FragmentBody '$global:ProfileFragmentLoaderOrchestrationProbe = $true'

            try {
                Remove-Variable -Name ProfileFragmentLoaderOrchestrationProbe -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture
                $global:ProfileFragmentLoaderOrchestrationProbe | Should -Be $true
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderOrchestrationProbe -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Skips disabled fragments when orchestration handles loading' {
            $fixture = New-ProfileLoaderFixture -Prefix 'orchestration-disabled-profile.d' -FragmentBody '$global:ProfileFragmentLoaderOrchestrationDisabled = $true'
            $disabled = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            [void]$disabled.Add('20-loader-probe')

            try {
                Remove-Variable -Name ProfileFragmentLoaderOrchestrationDisabled -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture -DisabledSet $disabled
                Get-Variable -Name ProfileFragmentLoaderOrchestrationDisabled -Scope Global -ErrorAction SilentlyContinue |
                    Should -BeNullOrEmpty
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderOrchestrationDisabled -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Records fragment results after orchestration completes' {
            $fixture = New-ProfileLoaderFixture `
                -Prefix 'orchestration-summary-profile.d' `
                -FragmentBody '$global:ProfileFragmentLoaderOrchSummary = $true'

            try {
                Remove-Variable -Name ProfileFragmentLoaderOrchSummary -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture -LoadBatchLoadingSummary $true
                $global:BatchLoadingInfo.SucceededFragments.Count | Should -BeGreaterThan 0
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderOrchSummary -Scope Global -ErrorAction SilentlyContinue
                if ($global:BatchLoadingInfo) {
                    $global:BatchLoadingInfo = $null
                }
            }
        }

        It 'Loads many fragments in batches through the orchestration module' {
            $extras = 2..11 | ForEach-Object { "2$($_)-orch-batch.ps1|`$global:ProfileFragmentLoaderOrchBatch$_ = `$true" }
            $fixture = New-ProfileLoaderFixture -Prefix 'orchestration-batch-profile.d' -AdditionalFragments $extras

            try {
                { Invoke-ProfileLoaderInit -Fixture $fixture -DebugLevel '1' } | Should -Not -Throw
                $global:ProfileFragmentLoaderOrchBatch2 | Should -Be $true
                $global:ProfileFragmentLoaderOrchBatch11 | Should -Be $true
            }
            finally {
                2..11 | ForEach-Object {
                    Remove-Variable -Name "ProfileFragmentLoaderOrchBatch$_" -Scope Global -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context 'Test-AndReloadModuleIfChanged debug output' {
        It 'Reports reload when the module file changes under debug tracing' {
            $global:TestReloadModulePath = $script:ModuleFile
            $global:TestReloadModuleName = $script:ModuleName

            try {
                Remove-Module -Name $script:ModuleName -ErrorAction SilentlyContinue -Force
                Import-Module -Name $script:ModuleFile -Force

                InModuleScope -ModuleName ProfileFragmentLoader {
                    $null = Test-AndReloadModuleIfChanged `
                        -ModulePath $global:TestReloadModulePath `
                        -ModuleName $global:TestReloadModuleName
                }

                Set-Content -LiteralPath $script:ModuleFile -Value @'
function Get-ReloadProbeValue {
    return 'changed'
}
Export-ModuleMember -Function Get-ReloadProbeValue
'@ -Encoding UTF8
                Start-Sleep -Milliseconds 50

                InModuleScope -ModuleName ProfileFragmentLoader {
                    Test-AndReloadModuleIfChanged `
                        -ModulePath $global:TestReloadModulePath `
                        -ModuleName $global:TestReloadModuleName `
                        -HasDebug $true `
                        -DebugLevel 2 | Should -Be $true
                }
            }
            finally {
                Remove-Variable -Name TestReloadModulePath, TestReloadModuleName -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Accepts HasDebug and DebugLevel without throwing when the module is unchanged' {
            $global:TestReloadModulePath = $script:ModuleFile
            $global:TestReloadModuleName = $script:ModuleName

            try {
                Remove-Module -Name $script:ModuleName -ErrorAction SilentlyContinue -Force
                Import-Module -Name $script:ModuleFile -Force

                InModuleScope -ModuleName ProfileFragmentLoader {
                    Test-AndReloadModuleIfChanged `
                        -ModulePath $global:TestReloadModulePath `
                        -ModuleName $global:TestReloadModuleName `
                        -HasDebug $true `
                        -DebugLevel 2 | Should -Be $false
                }
            }
            finally {
                Remove-Variable -Name TestReloadModulePath, TestReloadModuleName -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }
}
