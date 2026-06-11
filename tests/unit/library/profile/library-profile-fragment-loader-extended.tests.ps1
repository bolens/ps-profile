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
    $script:ProfileLibDir = Split-Path $script:LoaderPath -Parent
    $script:OrchestrationModulePath = Join-Path $script:ProfileLibDir 'ProfileFragmentLoadingOrchestration.psm1'
    $script:OrchestrationHiddenPath = "$script:OrchestrationModulePath.test-hidden"
    $script:InstalledTestSubmodulePaths = [System.Collections.Generic.List[string]]::new()
}

function script:Install-TestProfileSubmoduleStub {
    param(
        [Parameter(Mandatory)]
        [string]$FileName,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $targetPath = Join-Path $script:ProfileLibDir $FileName
    if (Test-Path -LiteralPath $targetPath) {
        return
    }

    Set-Content -LiteralPath $targetPath -Value $Content -Encoding UTF8
    [void]$script:InstalledTestSubmodulePaths.Add($targetPath)
}

function script:Remove-TestProfileSubmoduleStubs {
    foreach ($path in @($script:InstalledTestSubmodulePaths)) {
        if ($path -and (Test-Path -LiteralPath $path)) {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
    if ($script:InstalledTestSubmodulePaths) {
        $script:InstalledTestSubmodulePaths.Clear()
    }

    Remove-Module ProfileFragmentBootstrap, ProfileFragmentCacheInitialization, ProfileFragmentPreRegistration -ErrorAction SilentlyContinue -Force
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

function script:Install-TestLazyLoadingPassthroughModule {
    Remove-Module ProfileFragmentLazyLoading -ErrorAction SilentlyContinue -Force
    $null = New-Module -Name ProfileFragmentLazyLoading -ScriptBlock {
        function Handle-LazyLoadingMode {
            param(
                [bool]$LazyLoadEnabled,
                [System.Collections.Generic.List[System.IO.FileInfo]]$FragmentsToLoad,
                [System.Collections.Generic.HashSet[string]]$DisabledSet
            )

            # Keep lazy mode enabled but allow Initialize-FragmentLoading to continue
            # so proxy creation and other post-lazy paths remain reachable in tests.
            return $false
        }

        Export-ModuleMember -Function Handle-LazyLoadingMode
    } | Import-Module -Force -Global
}

function script:Remove-TestLazyLoadingPassthroughModule {
    Remove-Module ProfileFragmentLazyLoading -ErrorAction SilentlyContinue -Force
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
        [bool]$LoadBatchLoadingSummary = $true,
        [string]$FragmentLibDirOverride = $null,
        [string]$ProfileDOverride = $null
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
        if (-not (Get-Variable -Name BatchLoadingInfo -Scope Global -ErrorAction SilentlyContinue)) {
            $global:BatchLoadingInfo = $null
        }
        Initialize-BatchLoadingInfo
    }

    $fragmentLibDir = if ($FragmentLibDirOverride) { $FragmentLibDirOverride } else { $script:FragmentLibDir }
    $profileD = if ($ProfileDOverride) { $ProfileDOverride } else { $Fixture.ProfileD }

    try {
        Initialize-FragmentLoading `
            -FragmentsToLoad $Fixture.Fragments `
            -BootstrapFragment $BootstrapFragment `
            -DisabledSet $DisabledSet `
            -EnableParallelLoading $EnableParallelLoading `
            -FragmentLoadingModule $script:FragmentLoadingModule `
            -FragmentLoadingModuleExists $FragmentLoadingModuleExists `
            -FragmentLibDir $fragmentLibDir `
            -FragmentErrorHandlingModule $script:FragmentErrorHandlingModule `
            -FragmentErrorHandlingModuleExists $true `
            -ProfileD $profileD
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
    Remove-TestProfileSubmoduleStubs
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
            try {
                $fixture = New-ProfileLoaderFixture -Prefix 'bootstrap-profile.d'
                $bootstrapPath = Join-Path $fixture.ProfileD 'bootstrap.ps1'
                Set-Content -LiteralPath $bootstrapPath -Value '$global:ProfileFragmentLoaderBootstrapProbe = $true' -Encoding UTF8
                $bootstrap = Get-Item -LiteralPath $bootstrapPath

                            Remove-Variable -Name ProfileFragmentLoaderBootstrapProbe -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture -BootstrapFragment @($bootstrap)
                $global:ProfileFragmentLoaderBootstrapProbe | Should -Be $true
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderBootstrapProbe -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Skips fragments listed in DisabledSet' {
            try {
                $fixture = New-ProfileLoaderFixture -Prefix 'disabled-profile.d' -FragmentBody '$global:ProfileFragmentLoaderDisabledProbe = $true'
                $disabled = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                [void]$disabled.Add('20-loader-probe')

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
            try {
                $markerA = Join-Path $script:TempDir 'parallel-a.marker'
                $markerB = Join-Path $script:TempDir 'parallel-b.marker'
                $fixture = New-ProfileLoaderFixture `
                    -Prefix 'parallel-profile.d' `
                    -FragmentName '20-parallel-a.ps1' `
                    -FragmentBody "Set-Content -LiteralPath '$markerA' -Value 'ok' -Encoding UTF8" `
                    -AdditionalFragments @(
                    "30-parallel-b.ps1|Set-Content -LiteralPath '$markerB' -Value 'ok' -Encoding UTF8"
                )

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
            try {
                $fixture = New-ProfileLoaderFixture -Prefix 'lazy-profile.d' -FragmentBody '$global:ProfileFragmentLoaderLazyProbe = $true'

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
            try {
                $fixture = New-ProfileLoaderFixture `
                    -Prefix 'dependency-profile.d' `
                    -FragmentName '20-parent.ps1' `
                    -FragmentBody '$global:ProfileFragmentLoaderParentProbe = ''loaded''' `
                    -AdditionalFragments @(
                    '30-child.ps1|# Dependencies: 20-parent
    $global:ProfileFragmentLoaderChildProbe = ''loaded'''
                )

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
            try {
                $fixture = New-ProfileLoaderFixture -Prefix 'lazy-debug-profile.d'
                $originalDebug = $env:PS_PROFILE_DEBUG
                $env:PS_PROFILE_DEBUG = '2'

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
            try {
                $fixture = New-ProfileLoaderFixture -Prefix 'testmode-profile.d' -FragmentBody '$global:ProfileFragmentLoaderTestModeProbe = $true'

                            Remove-Variable -Name ProfileFragmentLoaderTestModeProbe -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture -EnableTestMode $true
                $global:ProfileFragmentLoaderTestModeProbe | Should -Be $true
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderTestModeProbe -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Survives failing bootstrap fragments without terminating initialization' {
            try {
                $fixture = New-ProfileLoaderFixture -Prefix 'bootstrap-fail-profile.d'
                $bootstrapPath = Join-Path $fixture.ProfileD 'bootstrap.ps1'
                Set-Content -LiteralPath $bootstrapPath -Value 'throw "bootstrap failure probe"' -Encoding UTF8
                $bootstrap = Get-Item -LiteralPath $bootstrapPath
                $previousErrorAction = $ErrorActionPreference

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
            try {
                $extras = 2..4 | ForEach-Object { "2$($_)-batch-debug.ps1|`$global:ProfileFragmentLoaderBatch$_ = `$true" }
                $fixture = New-ProfileLoaderFixture -Prefix 'batch-debug-profile.d' -AdditionalFragments $extras

                            Remove-Variable -Name ProfileFragmentLoaderBatch2, ProfileFragmentLoaderBatch3, ProfileFragmentLoaderBatch4 -Scope Global -ErrorAction SilentlyContinue
                { Invoke-ProfileLoaderInit -Fixture $fixture -DebugLevel '1' } | Should -Not -Throw
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderBatch2, ProfileFragmentLoaderBatch3, ProfileFragmentLoaderBatch4 -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Runs dependency analysis output when parallel loading and debug are enabled' {
            try {
                $markerA = Join-Path $script:TempDir 'dep-a.marker'
                $markerB = Join-Path $script:TempDir 'dep-b.marker'
                $fixture = New-ProfileLoaderFixture `
                    -Prefix 'dep-debug-profile.d' `
                    -FragmentName '20-dep-a.ps1' `
                    -FragmentBody "Set-Content -LiteralPath '$markerA' -Value 'ok' -Encoding UTF8" `
                    -AdditionalFragments @("30-dep-b.ps1|Set-Content -LiteralPath '$markerB' -Value 'ok' -Encoding UTF8")
                $originalDebug = $env:PS_PROFILE_DEBUG
                $env:PS_PROFILE_DEBUG = '2'

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
            try {
                Enable-TestStructuredLogging
                $fixture = New-ProfileLoaderFixture -Prefix 'orchestration-warning-profile.d'

                Hide-TestOrchestrationModule
                            { Invoke-ProfileLoaderInit -Fixture $fixture } | Should -Not -Throw
            }
            finally {
                Restore-TestOrchestrationModule
            }
        }

        It 'Survives cache pre-warming failures when sqlite helpers are available' {
            try {
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
            try {
                $fixture = New-ProfileLoaderFixture `
                    -Prefix 'batch-summary-profile.d' `
                    -FragmentName '20-batch-ok.ps1' `
                    -FragmentBody '$global:ProfileFragmentLoaderBatchOk = $true' `
                    -AdditionalFragments @('30-batch-fail.ps1|throw "batch summary failure probe"')

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
            try {
                Enable-TestStructuredLogging
                $fixture = New-ProfileLoaderFixture -Prefix 'pre-register-fail-profile.d'
                $registryPath = Join-Path $script:FragmentLibDir 'FragmentCommandRegistry.psm1'
                Import-Module $registryPath -DisableNameChecking -Force -Global
                Mock Register-AllFragmentCommands {
                    throw 'pre-register failure probe'
                } -ModuleName FragmentCommandRegistry

                            { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -DebugLevel '1' } | Should -Not -Throw
            }
            finally {
                Remove-Module FragmentCommandRegistry -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Uses Write-Warning when dependency grouping fails without structured helpers' {
            try {
                $fixture = New-ProfileLoaderFixture -Prefix 'grouping-warning-profile.d'
                Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
                Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force

                Import-Module $script:FragmentLoadingModule -DisableNameChecking -Force -Global
                Mock Get-FragmentDependencyLevels {
                    throw 'dependency grouping warning probe'
                } -ModuleName FragmentLoading

                            { Invoke-ProfileLoaderInit -Fixture $fixture -EnableParallelLoading $true -DebugLevel '1' } | Should -Not -Throw
            }
            finally {
                Remove-Module FragmentLoading -Force -ErrorAction SilentlyContinue
                Import-Module $script:FragmentLoadingModule -DisableNameChecking -Force -Global
            }
        }

        It 'Falls back to sequential loading when dependency grouping fails' {
            try {
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
            try {
                Ensure-TestOrchestrationModule
                $extras = 2..4 | ForEach-Object { "2$($_)-dep-meta.ps1|# fragment $_" }
                $fixture = New-ProfileLoaderFixture -Prefix 'dep-meta-profile.d' -AdditionalFragments $extras

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
            try {
                Enable-TestStructuredLogging
                $fixture = New-ProfileLoaderFixture -Prefix 'bootstrap-structured-profile.d'
                $bootstrapPath = Join-Path $fixture.ProfileD 'bootstrap.ps1'
                Set-Content -LiteralPath $bootstrapPath -Value 'throw "bootstrap structured probe"' -Encoding UTF8
                $bootstrap = Get-Item -LiteralPath $bootstrapPath
                $previousErrorAction = $ErrorActionPreference

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
            try {
                $fixture = New-ProfileLoaderFixture `
                    -Prefix 'orchestration-load-profile.d' `
                    -FragmentBody '$global:ProfileFragmentLoaderOrchestrationProbe = $true'

                            Remove-Variable -Name ProfileFragmentLoaderOrchestrationProbe -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture
                $global:ProfileFragmentLoaderOrchestrationProbe | Should -Be $true
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderOrchestrationProbe -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Skips disabled fragments when orchestration handles loading' {
            try {
                $fixture = New-ProfileLoaderFixture -Prefix 'orchestration-disabled-profile.d' -FragmentBody '$global:ProfileFragmentLoaderOrchestrationDisabled = $true'
                $disabled = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                [void]$disabled.Add('20-loader-probe')

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
            try {
                $fixture = New-ProfileLoaderFixture `
                    -Prefix 'orchestration-summary-profile.d' `
                    -FragmentBody '$global:ProfileFragmentLoaderOrchSummary = $true'

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
            try {
                $extras = 2..11 | ForEach-Object { "2$($_)-orch-batch.ps1|`$global:ProfileFragmentLoaderOrchBatch$_ = `$true" }
                $fixture = New-ProfileLoaderFixture -Prefix 'orchestration-batch-profile.d' -AdditionalFragments $extras

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

        It 'Returns false when Get-Item cannot resolve the module path' {
            $global:TestReloadModulePath = $script:ModuleFile
            $global:TestReloadModuleName = $script:ModuleName

            try {
                Mock Get-Item { return $null } -ParameterFilter { $LiteralPath -eq $script:ModuleFile }

                InModuleScope -ModuleName ProfileFragmentLoader {
                    Test-AndReloadModuleIfChanged `
                        -ModulePath $global:TestReloadModulePath `
                        -ModuleName $global:TestReloadModuleName | Should -Be $false
                }
            }
            finally {
                Remove-Variable -Name TestReloadModulePath, TestReloadModuleName -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Returns false when the module path disappears between Test-Path and Get-Item' {
            $global:TestMissingModulePath = Join-Path $script:TempDir 'vanished-module.psm1'
            Set-Content -LiteralPath $global:TestMissingModulePath -Value 'Export-ModuleMember' -Encoding UTF8
            Remove-Item -LiteralPath $global:TestMissingModulePath -Force

            try {
                InModuleScope -ModuleName ProfileFragmentLoader {
                    Test-AndReloadModuleIfChanged -ModulePath $global:TestMissingModulePath -ModuleName 'VanishedModule' |
                        Should -Be $false
                }
            }
            finally {
                Remove-Variable -Name TestMissingModulePath -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Batch progress helpers' {
        It 'Renders zero-percent progress when total batches is zero' {
            InModuleScope -ModuleName ProfileFragmentLoader {
                { Write-BatchProgressRow -BatchNumber 0 -TotalBatches 0 -FragmentCount 0 -FragmentNames @('none') } |
                    Should -Not -Throw
            }
        }

        It 'Truncates long fragment name lists in progress rows' {
            InModuleScope -ModuleName ProfileFragmentLoader {
                $names = 1..12 | ForEach-Object { "fragment-$_" }
                { Write-BatchProgressRow -BatchNumber 1 -TotalBatches 1 -FragmentCount 12 -FragmentNames $names } |
                    Should -Not -Throw
            }
        }

        It 'Prints the batch table header only once per initialization' {
            InModuleScope -ModuleName ProfileFragmentLoader {
                Write-BatchProgressTableHeader
                { Write-BatchProgressTableHeader } | Should -Not -Throw
            }
        }
    }

    Context 'Lazy loading continuation and proxy creation' {
        AfterEach {
            Remove-TestLazyLoadingPassthroughModule
        }

        It 'Continues initialization when lazy loading module declines early return' {
            try {
                Install-TestLazyLoadingPassthroughModule
                $fixture = New-ProfileLoaderFixture -Prefix 'lazy-continue-profile.d' -FragmentBody @'
function Get-ProfileLoaderLazyContinueProbe {
    return 'ok'
}
'@

                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -DebugLevel '2' } | Should -Not -Throw
            }
            finally {
                Remove-TestLazyLoadingPassthroughModule
            }
        }

        It 'Creates command proxies when lazy loading continues with debug tracing' {
            try {
                Enable-TestStructuredLogging
                Install-TestLazyLoadingPassthroughModule
                Import-Module $script:FragmentLibDir/FragmentCommandRegistry.psm1 -DisableNameChecking -Force -Global
                Mock Create-CommandProxiesForAutocomplete {
                    return [PSCustomObject]@{
                        TotalCommands  = 4
                        CreatedProxies = 3
                        FailedProxies  = 1
                    }
                } -ModuleName FragmentCommandRegistry

                $fixture = New-ProfileLoaderFixture -Prefix 'proxy-create-profile.d' -FragmentBody @'
function Get-ProfileLoaderProxyCreateProbe {
    return 'proxy-create'
}
'@

                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -EnableProxyCreation $true -DebugLevel '2' } |
                    Should -Not -Throw
            }
            finally {
                Remove-Module FragmentCommandRegistry -Force -ErrorAction SilentlyContinue
                Remove-TestLazyLoadingPassthroughModule
            }
        }

        It 'Uses Write-Warning for proxy creation failures without structured helpers' {
            try {
                Disable-TestStructuredLogging
                Install-TestLazyLoadingPassthroughModule
                function global:Create-CommandProxiesForAutocomplete {
                    throw 'proxy warning probe'
                }
                $fixture = New-ProfileLoaderFixture -Prefix 'proxy-warning-profile.d'

                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -EnableProxyCreation $true -DebugLevel '1' -WarningVariable warnings } |
                    Should -Not -Throw
            }
            finally {
                Remove-Item -Path Function:\Create-CommandProxiesForAutocomplete -ErrorAction SilentlyContinue -Force
                Remove-TestLazyLoadingPassthroughModule
            }
        }

        It 'Uses Write-Warning when dependency grouping fails without structured helpers' {
            try {
                Disable-TestStructuredLogging
                Install-TestLazyLoadingPassthroughModule
                Import-Module $script:FragmentLoadingModule -DisableNameChecking -Force -Global
                Mock Get-FragmentDependencyLevels {
                    throw 'dependency grouping warning probe'
                } -ModuleName FragmentLoading

                $fixture = New-ProfileLoaderFixture -Prefix 'grouping-plain-warning-profile.d'
                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableParallelLoading $true -EnableLazyLoading $true -DebugLevel '1' -WarningVariable warnings } |
                    Should -Not -Throw
            }
            finally {
                Remove-Module FragmentLoading -Force -ErrorAction SilentlyContinue
                Import-Module $script:FragmentLoadingModule -DisableNameChecking -Force -Global
                Remove-TestLazyLoadingPassthroughModule
            }
        }

        It 'Uses orchestration fallback while lazy loading continues' {
            try {
                Enable-TestStructuredLogging
                Install-TestLazyLoadingPassthroughModule
                Hide-TestOrchestrationModule
                $fixture = New-ProfileLoaderFixture -Prefix 'fallback-orchestration-profile.d' -FragmentBody '$global:ProfileFragmentLoaderFallbackOrch = $true'

                Remove-Variable -Name ProfileFragmentLoaderFallbackOrch -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true
                $global:ProfileFragmentLoaderFallbackOrch | Should -Be $true
            }
            finally {
                Restore-TestOrchestrationModule
                Remove-Variable -Name ProfileFragmentLoaderFallbackOrch -Scope Global -ErrorAction SilentlyContinue
                Remove-TestLazyLoadingPassthroughModule
            }
        }

        It 'Survives proxy creation failures when lazy loading continues' {
            try {
                Enable-TestStructuredLogging
                Install-TestLazyLoadingPassthroughModule
                Import-Module $script:FragmentLibDir/FragmentCommandRegistry.psm1 -DisableNameChecking -Force -Global
                Mock Create-CommandProxiesForAutocomplete {
                    throw 'proxy creation probe'
                } -ModuleName FragmentCommandRegistry

                $fixture = New-ProfileLoaderFixture -Prefix 'proxy-fail-profile.d' -FragmentBody 'function Get-ProfileLoaderProxyFailProbe { "ok" }'
                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -EnableProxyCreation $true -DebugLevel '1' } |
                    Should -Not -Throw
            }
            finally {
                Remove-Module FragmentCommandRegistry -Force -ErrorAction SilentlyContinue
                Remove-TestLazyLoadingPassthroughModule
            }
        }

        It 'Reports missing proxy helpers when Create-CommandProxiesForAutocomplete is unavailable' {
            try {
                Install-TestLazyLoadingPassthroughModule
                Remove-Item -Path Function:\Create-CommandProxiesForAutocomplete -ErrorAction SilentlyContinue -Force
                $fixture = New-ProfileLoaderFixture -Prefix 'proxy-missing-profile.d'

                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -EnableProxyCreation $true -DebugLevel '1' } |
                    Should -Not -Throw
            }
            finally {
                Remove-TestLazyLoadingPassthroughModule
            }
        }

        It 'Reports when proxy creation is disabled through PS_PROFILE_CREATE_PROXIES' {
            try {
                Install-TestLazyLoadingPassthroughModule
                $fixture = New-ProfileLoaderFixture -Prefix 'proxy-disabled-profile.d'
                $previous = $env:PS_PROFILE_CREATE_PROXIES
                $env:PS_PROFILE_CREATE_PROXIES = '0'

                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -DebugLevel '1' } | Should -Not -Throw
            }
            finally {
                if ($null -eq $previous) { Remove-Item Env:PS_PROFILE_CREATE_PROXIES -ErrorAction SilentlyContinue }
                else { $env:PS_PROFILE_CREATE_PROXIES = $previous }
                Remove-TestLazyLoadingPassthroughModule
            }
        }

        It 'Lists many fragments under lazy loading with level 3 debug tracing' {
            try {
                Install-TestLazyLoadingPassthroughModule
                $extras = 2..14 | ForEach-Object { "1$($_)-lazy-list.ps1|# fragment $_" }
                $fixture = New-ProfileLoaderFixture -Prefix 'lazy-list-profile.d' -AdditionalFragments $extras

                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -DebugLevel '3' } | Should -Not -Throw
            }
            finally {
                Remove-TestLazyLoadingPassthroughModule
            }
        }

        It 'Runs pre-registration summary output when lazy loading continues' {
            try {
                Install-TestLazyLoadingPassthroughModule
                $extras = 2..3 | ForEach-Object { "2$($_)-prereg.ps1|function Get-ProfileLoaderPreReg$_ { 'ok' }" }
                $fixture = New-ProfileLoaderFixture -Prefix 'prereg-summary-profile.d' -AdditionalFragments $extras

                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -DebugLevel '2' } | Should -Not -Throw
            }
            finally {
                Remove-TestLazyLoadingPassthroughModule
            }
        }

        It 'Loads bootstrap fragments through the inline bootstrap module path' {
            try {
                $fixture = New-ProfileLoaderFixture -Prefix 'inline-bootstrap-profile.d'
                $bootstrapPath = Join-Path $fixture.ProfileD 'bootstrap.ps1'
                Set-Content -LiteralPath $bootstrapPath -Value '$global:ProfileFragmentLoaderInlineBootstrap = $true' -Encoding UTF8
                $bootstrap = Get-Item -LiteralPath $bootstrapPath

                Remove-Variable -Name ProfileFragmentLoaderInlineBootstrap -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture -BootstrapFragment @($bootstrap) -DebugLevel '3'
                $global:ProfileFragmentLoaderInlineBootstrap | Should -Be $true
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderInlineBootstrap -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Initializes fragment cache fallback when cache initialization module is unavailable' {
            $fixture = New-ProfileLoaderFixture -Prefix 'cache-fallback-profile.d'
            { Invoke-ProfileLoaderInit -Fixture $fixture -DebugLevel '2' } | Should -Not -Throw
        }

        It 'Runs parallel dependency analysis output at debug level 2' {
            try {
                Install-TestLazyLoadingPassthroughModule
                $extras = 2..4 | ForEach-Object { "2$($_)-dep-analysis.ps1|# fragment $_" }
                $fixture = New-ProfileLoaderFixture -Prefix 'dep-analysis-profile.d' -AdditionalFragments $extras

                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableParallelLoading $true -EnableLazyLoading $true -DebugLevel '2' } |
                    Should -Not -Throw
            }
            finally {
                Remove-TestLazyLoadingPassthroughModule
            }
        }

        It 'Resolves the command registry through ProfileD when FragmentLibDir is invalid' {
            try {
                Install-TestLazyLoadingPassthroughModule
                Import-Module $script:FragmentLibDir/FragmentCommandRegistry.psm1 -DisableNameChecking -Force -Global
                Mock Create-CommandProxiesForAutocomplete {
                    return [PSCustomObject]@{ TotalCommands = 1; CreatedProxies = 1; FailedProxies = 0 }
                } -ModuleName FragmentCommandRegistry

                $profileD = Join-Path $script:RepoRoot 'profile.d'
                $fixture = New-ProfileLoaderFixture -Prefix 'registry-fallback-profile.d' -FragmentBody 'function Get-ProfileLoaderRegistryFallbackProbe { "ok" }'
                $invalidLibDir = Join-Path $script:TempDir 'missing-fragment-lib'

                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -EnableProxyCreation $true -DebugLevel '2' -FragmentLibDirOverride $invalidLibDir -ProfileDOverride $profileD } |
                    Should -Not -Throw
            }
            finally {
                Remove-Module FragmentCommandRegistry -Force -ErrorAction SilentlyContinue
                Remove-TestLazyLoadingPassthroughModule
            }
        }

        It 'Records bootstrap failures with structured errors when debug is disabled' {
            try {
                Enable-TestStructuredLogging
                $fixture = New-ProfileLoaderFixture -Prefix 'bootstrap-no-debug-profile.d'
                $bootstrapPath = Join-Path $fixture.ProfileD 'bootstrap.ps1'
                Set-Content -LiteralPath $bootstrapPath -Value 'throw "bootstrap no debug probe"' -Encoding UTF8
                $bootstrap = Get-Item -LiteralPath $bootstrapPath
                $previousErrorAction = $ErrorActionPreference

                $ErrorActionPreference = 'Continue'
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                { Invoke-ProfileLoaderInit -Fixture $fixture -BootstrapFragment @($bootstrap) } | Should -Not -Throw
            }
            finally {
                $ErrorActionPreference = $previousErrorAction
            }
        }

        It 'Uses optional profile submodule stubs when they are present on disk' {
            try {
                Install-TestProfileSubmoduleStub -FileName 'ProfileFragmentCacheInitialization.psm1' -Content @'
function Initialize-FragmentCacheForLoading {
    param([string]$FragmentLibDir, [bool]$HasDebug, [int]$DebugLevel)
}
function Pre-WarmFragmentCache {
    param([System.Collections.Generic.List[System.IO.FileInfo]]$FragmentsToLoad, [bool]$HasDebug, [int]$DebugLevel)
}
Export-ModuleMember -Function Initialize-FragmentCacheForLoading, Pre-WarmFragmentCache
'@
                Install-TestProfileSubmoduleStub -FileName 'ProfileFragmentBootstrap.psm1' -Content @'
function Invoke-BootstrapFragmentLoading {
    param(
        [System.IO.FileInfo[]]$BootstrapFragment,
        [System.Collections.Generic.HashSet[string]]$AllSucceeded,
        [System.Collections.Generic.List[hashtable]]$AllFailed,
        [System.Collections.Generic.HashSet[string]]$FailedNames
    )

    $bootstrapNameSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($bf in @($BootstrapFragment)) {
        if ($bf -and $bf.BaseName) {
            [void]$bootstrapNameSet.Add($bf.BaseName)
            try {
                $null = . $bf.FullName
                [void]$AllSucceeded.Add($bf.BaseName)
            }
            catch {
                if (-not $FailedNames.Contains($bf.BaseName)) {
                    $AllFailed.Add(@{ Name = $bf.BaseName; Error = $_.Exception.Message })
                    [void]$FailedNames.Add($bf.BaseName)
                }
            }
        }
    }
    return $bootstrapNameSet
}
Export-ModuleMember -Function Invoke-BootstrapFragmentLoading
'@
                Install-TestProfileSubmoduleStub -FileName 'ProfileFragmentPreRegistration.psm1' -Content @'
function Invoke-FragmentCommandPreRegistration {
    param(
        [System.Collections.Generic.List[System.IO.FileInfo]]$FragmentsToLoad,
        [string]$FragmentLibDir,
        [string]$ProfileD
    )

    return [PSCustomObject]@{
        TotalFragments     = $FragmentsToLoad.Count
        RegisteredCommands = 0
        FailedFragments    = 0
    }
}
Export-ModuleMember -Function Invoke-FragmentCommandPreRegistration
'@

                $fixture = New-ProfileLoaderFixture -Prefix 'submodule-stub-profile.d'
                $bootstrapPath = Join-Path $fixture.ProfileD 'bootstrap.ps1'
                Set-Content -LiteralPath $bootstrapPath -Value '$global:ProfileFragmentLoaderSubmoduleBootstrap = $true' -Encoding UTF8
                $bootstrap = Get-Item -LiteralPath $bootstrapPath

                Remove-Variable -Name ProfileFragmentLoaderSubmoduleBootstrap -Scope Global -ErrorAction SilentlyContinue
                Invoke-ProfileLoaderInit -Fixture $fixture -BootstrapFragment @($bootstrap) -EnablePrewarmCache $true -DebugLevel '2'
                $global:ProfileFragmentLoaderSubmoduleBootstrap | Should -Be $true
            }
            finally {
                Remove-Variable -Name ProfileFragmentLoaderSubmoduleBootstrap -Scope Global -ErrorAction SilentlyContinue
                Remove-TestProfileSubmoduleStubs
            }
        }

        It 'Reports created proxy counts at debug level 1 when proxies are created' {
            try {
                Install-TestLazyLoadingPassthroughModule
                Import-Module $script:FragmentLibDir/FragmentCommandRegistry.psm1 -DisableNameChecking -Force -Global
                Mock Create-CommandProxiesForAutocomplete {
                    return [PSCustomObject]@{
                        TotalCommands  = 2
                        CreatedProxies = 2
                        FailedProxies  = 0
                    }
                } -ModuleName FragmentCommandRegistry

                $fixture = New-ProfileLoaderFixture -Prefix 'proxy-count-profile.d'
                { Invoke-ProfileLoaderInit -Fixture $fixture -EnableLazyLoading $true -EnableProxyCreation $true -DebugLevel '1' } |
                    Should -Not -Throw
            }
            finally {
                Remove-Module FragmentCommandRegistry -Force -ErrorAction SilentlyContinue
                Remove-TestLazyLoadingPassthroughModule
            }
        }

        It 'Uses Write-Error for bootstrap failures when structured logging is unavailable' {
            try {
                Disable-TestStructuredLogging
                $fixture = New-ProfileLoaderFixture -Prefix 'bootstrap-write-error-profile.d'
                $bootstrapPath = Join-Path $fixture.ProfileD 'bootstrap.ps1'
                Set-Content -LiteralPath $bootstrapPath -Value 'throw "bootstrap write-error probe"' -Encoding UTF8
                $bootstrap = Get-Item -LiteralPath $bootstrapPath
                $previousErrorAction = $ErrorActionPreference

                $ErrorActionPreference = 'Continue'
                { Invoke-ProfileLoaderInit -Fixture $fixture -BootstrapFragment @($bootstrap) -DebugLevel '1' } | Should -Not -Throw
            }
            finally {
                $ErrorActionPreference = $previousErrorAction
            }
        }
    }
}
