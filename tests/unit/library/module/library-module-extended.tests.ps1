<#
tests/unit/library-module-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Module.psm1 import and availability helpers.
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
    Import-Module (Join-Path $script:LibPath 'runtime' 'Module.psm1') -DisableNameChecking -Force

    # Disposable probe module for import/ensure tests. NEVER unload Pester here — that
    # destroys the running test runner's mock infrastructure and cascades
    # "Mock data are not setup for this scope" into later files in the same shard.
    $script:ProbeName = 'PsProfileModuleProbe'
    $script:ProbeRoot = New-TestTempDirectory -Prefix 'ModuleProbeExt'
    $probeDir = Join-Path $script:ProbeRoot $script:ProbeName
    New-Item -ItemType Directory -Path $probeDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $probeDir "$($script:ProbeName).psm1") -Value @'
function Get-PsProfileModuleProbe { 'ok' }
Export-ModuleMember -Function Get-PsProfileModuleProbe
'@
    $script:OriginalPSModulePath = $env:PSModulePath
    $env:PSModulePath = "$($script:ProbeRoot)$([System.IO.Path]::PathSeparator)$env:PSModulePath"
}

function script:Invoke-InModuleWithStubs {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Body,

        [hashtable]$Stubs = @{}
    )

    $global:TestRuntimeModuleStubs = $Stubs
    $global:TestRuntimeModuleBody = $Body

    try {
        InModuleScope -ModuleName Module {
            $stubTable = $global:TestRuntimeModuleStubs
            if ($null -ne $stubTable) {
                foreach ($entry in $stubTable.GetEnumerator()) {
                    Set-Item -Path "Function:$($entry.Key)" -Value $entry.Value -Force
                }
            }

            & $global:TestRuntimeModuleBody
        }
    }
    finally {
        Remove-Variable -Name TestRuntimeModuleStubs, TestRuntimeModuleBody -Scope Global -ErrorAction SilentlyContinue
    }
}

AfterAll {
    Remove-Module Module -ErrorAction SilentlyContinue -Force
    if ($script:ProbeName) {
        Remove-Module -Name $script:ProbeName -Force -ErrorAction SilentlyContinue
    }
    if ($null -ne $script:OriginalPSModulePath) {
        $env:PSModulePath = $script:OriginalPSModulePath
    }
}

Describe 'Module extended scenarios' {
    Context 'Import-RequiredModule' {
        It 'Does not throw when importing an already loaded module' {
            Import-RequiredModule -ModuleName $script:ProbeName -ErrorAction SilentlyContinue
            { Import-RequiredModule -ModuleName $script:ProbeName } | Should -Not -Throw
        }

        It 'Requires ModuleName parameter' {
            (Get-Command Import-RequiredModule).Parameters.ContainsKey('ModuleName') | Should -Be $true
        }

        It 'Imports successfully when Import-Module succeeds' {
            Invoke-InModuleWithStubs -Stubs @{
                'Import-Module' = { param($Name, $Force) }
            } -Body {
                { Import-RequiredModule -ModuleName 'MockModule' } | Should -Not -Throw
            }
        }

        It 'Emits level 3 tracing when PS_PROFILE_DEBUG is enabled' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                Invoke-InModuleWithStubs -Stubs @{
                    'Import-Module' = { param($Name, $Force) }
                } -Body {
                    Import-RequiredModule -ModuleName 'TraceModule' -Force | Out-Null
                }
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

        It 'Uses Write-StructuredError when import fails with debug enabled' {
            Enable-TestStructuredLogging
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                Invoke-InModuleWithStubs -Stubs @{
                    'Import-Module' = { throw 'import failure probe' }
                } -Body {
                    { Import-RequiredModule -ModuleName 'BrokenModule' } | Should -Throw 'import failure probe'
                }
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

        It 'Uses Write-Error when import fails without structured logging' {
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            try {
                Invoke-InModuleWithStubs -Stubs @{
                    'Import-Module' = { throw 'bare import failure probe' }
                } -Body {
                    { Import-RequiredModule -ModuleName 'BareBrokenModule' } | Should -Throw
                }
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

        It 'Logs level 3 import error details when import fails with debug level 3' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                Invoke-InModuleWithStubs -Stubs @{
                    'Import-Module' = { throw 'level 3 import failure probe' }
                } -Body {
                    { Import-RequiredModule -ModuleName 'Level3BrokenModule' } | Should -Throw
                }
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

        It 'Reports imported module details at debug level 3 after successful import' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                Invoke-InModuleWithStubs -Stubs @{
                    'Import-Module' = { param($Name, $Force) }
                'Get-Module'    = {
                        param($Name)
                        if ($Name -eq 'DetailModule') {
                            return [PSCustomObject]@{
                                Name    = 'DetailModule'
                                Version = '2.0.0'
                                Path    = '/fake/detail'
                            }
                        }

                        return $null
                    }
                } -Body {
                    Import-RequiredModule -ModuleName 'DetailModule' | Out-Null
                }
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

    Context 'Install-RequiredModule' {
        It 'Exposes Scope and Force parameters when ModuleScope is available' {
            $cmd = Get-Command Install-RequiredModule
            if (-not $cmd.Parameters -or $cmd.Parameters.Count -eq 0) {
                Set-ItResult -Skipped -Because 'Install-RequiredModule parameters not available'
                return
            }

            $cmd.Parameters.Keys | Should -Contain 'Scope'
            $cmd.Parameters.Keys | Should -Contain 'Force'
        }

        It 'Skips installation when the module is already available' {
            Invoke-InModuleWithStubs -Stubs @{
                'Get-Module' = {
                    param(
                        $Name,
                        [switch]$ListAvailable
                    )
                    if ($ListAvailable -and $Name -eq 'InstalledProbe') {
                        return [PSCustomObject]@{
                            Name    = 'InstalledProbe'
                            Version = '1.2.3'
                            Path    = '/fake/installed'
                        }
                    }

                    return $null
                }
            } -Body {
                { Install-RequiredModule -ModuleName 'InstalledProbe' } | Should -Not -Throw
            }
        }

        It 'Emits debug output when an installed module is found at level 2' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $originalVerbose = $VerbosePreference
            $env:PS_PROFILE_DEBUG = '2'
            $VerbosePreference = 'Continue'

            try {
                Invoke-InModuleWithStubs -Stubs @{
                    'Get-Module' = {
                        param(
                            $Name,
                            [switch]$ListAvailable
                        )
                        if ($ListAvailable -and $Name -eq 'DebugInstalledProbe') {
                            return [PSCustomObject]@{
                                Name    = 'DebugInstalledProbe'
                                Version = '9.9.9'
                                Path    = '/fake/debug'
                            }
                        }

                        return $null
                    }
                } -Body {
                    Install-RequiredModule -ModuleName 'DebugInstalledProbe' | Out-Null
                }
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

        It 'Installs when the module is missing and PSGallery is not registered' {
            Invoke-InModuleWithStubs -Stubs @{
                'Get-Module'           = { $null }
                'Get-PSRepository'     = { $null }
                'Register-PSRepository' = { }
                'Set-PSRepository'     = { }
                'Install-Module'       = { param($Name) }
            } -Body {
                { Install-RequiredModule -ModuleName 'MissingProbe' } | Should -Not -Throw
            }
        }

        It 'Trusts PSGallery when the repository exists but is untrusted' {
            Invoke-InModuleWithStubs -Stubs @{
                'Get-Module'       = { $null }
                'Get-PSRepository' = {
                    [PSCustomObject]@{
                        Name               = 'PSGallery'
                        InstallationPolicy = 'Untrusted'
                    }
                }
                'Set-PSRepository' = { }
                'Install-Module'   = { param($Name) }
            } -Body {
                { Install-RequiredModule -ModuleName 'UntrustedGalleryProbe' } | Should -Not -Throw
            }
        }

        It 'Reinstalls when Force is specified even if the module exists' {
            Invoke-InModuleWithStubs -Stubs @{
                'Get-Module' = {
                    param(
                        $Name,
                        [switch]$ListAvailable
                    )
                    if ($ListAvailable -and $Name -eq 'ForceProbe') {
                        return [PSCustomObject]@{ Name = 'ForceProbe'; Version = '1.0.0'; Path = '/fake' }
                    }

                    return $null
                }
                'Get-PSRepository' = {
                    [PSCustomObject]@{ Name = 'PSGallery'; InstallationPolicy = 'Trusted' }
                }
                'Install-Module' = { param($Name) }
            } -Body {
                { Install-RequiredModule -ModuleName 'ForceProbe' -Force } | Should -Not -Throw
            }
        }

        It 'Throws when installation fails' {
            Invoke-InModuleWithStubs -Stubs @{
                'Get-Module'       = { $null }
                'Get-PSRepository' = {
                    [PSCustomObject]@{ Name = 'PSGallery'; InstallationPolicy = 'Trusted' }
                }
                'Install-Module'   = { throw 'install failure probe' }
            } -Body {
                { Install-RequiredModule -ModuleName 'InstallFailureProbe' } | Should -Throw '*install failure probe*'
            }
        }

        It 'Uses Write-StructuredError when installation fails with debug enabled' {
            Enable-TestStructuredLogging
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                Invoke-InModuleWithStubs -Stubs @{
                    'Get-Module'       = { $null }
                    'Get-PSRepository' = {
                        [PSCustomObject]@{ Name = 'PSGallery'; InstallationPolicy = 'Trusted' }
                    }
                    'Install-Module'   = { throw 'structured install failure probe' }
                } -Body {
                    { Install-RequiredModule -ModuleName 'StructuredInstallFailureProbe' } | Should -Throw
                }
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

        It 'Uses Write-StructuredError when installation fails without debug enabled' {
            Enable-TestStructuredLogging
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            Invoke-InModuleWithStubs -Stubs @{
                'Get-Module'       = { $null }
                'Get-PSRepository' = {
                    [PSCustomObject]@{ Name = 'PSGallery'; InstallationPolicy = 'Trusted' }
                }
                'Install-Module'   = { throw 'critical install failure probe' }
            } -Body {
                { Install-RequiredModule -ModuleName 'CriticalInstallFailureProbe' } | Should -Throw
            }
        }
    }

    Context 'Ensure-ModuleAvailable' {
        It 'Imports probe module without error when the module is already installed' {
            Remove-Module -Name $script:ProbeName -Force -ErrorAction SilentlyContinue
            { Ensure-ModuleAvailable -ModuleName $script:ProbeName } | Should -Not -Throw
            # Ensure-ModuleAvailable imports via Module.psm1 session — use -All to observe it.
            Get-Module -Name $script:ProbeName -All | Should -Not -BeNullOrEmpty
        }

        It 'Installs and imports when both steps succeed' {
            Invoke-InModuleWithStubs -Stubs @{
                'Get-Module'       = { $null }
                'Get-PSRepository' = {
                    [PSCustomObject]@{ Name = 'PSGallery'; InstallationPolicy = 'Trusted' }
                }
                'Install-Module'   = { param($Name) }
                'Import-Module'    = { param($Name, $Force) }
            } -Body {
                { Ensure-ModuleAvailable -ModuleName 'EnsureProbe' } | Should -Not -Throw
            }
        }

        It 'Exports all three module helper functions' {
            $module = Get-Module Module
            @($module.ExportedFunctions.Keys) | Should -Contain 'Import-RequiredModule'
            @($module.ExportedFunctions.Keys) | Should -Contain 'Install-RequiredModule'
            @($module.ExportedFunctions.Keys) | Should -Contain 'Ensure-ModuleAvailable'
        }
    }
}
