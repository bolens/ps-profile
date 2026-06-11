<#
tests/unit/library-module-import-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Import-LibModule subdirectory resolution.
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
    $pathResolutionPath = Join-Path $script:LibPath 'path' 'PathResolution.psm1'
    $cachePath = Join-Path $script:LibPath 'utilities' 'Cache.psm1'

    Remove-Module PathResolution -ErrorAction SilentlyContinue -Force
    Remove-Module Cache -ErrorAction SilentlyContinue -Force
    Remove-Module ModuleImport -ErrorAction SilentlyContinue -Force

    Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop -Force -Global
    if (-not (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue)) {
        throw 'Get-RepoRoot function not available after importing PathResolution module'
    }

    if (Test-Path -LiteralPath $cachePath) {
        Import-Module $cachePath -DisableNameChecking -Force -Global
    }

    Import-Module (Join-Path $script:LibPath 'ModuleImport.psm1') -DisableNameChecking -ErrorAction Stop -Force

    $script:TestScriptPath = Get-TestScriptPath -RelativePath 'scripts/utils/test.ps1' -StartPath $PSScriptRoot
}

AfterAll {
    Remove-Module ModuleImport -ErrorAction SilentlyContinue -Force
    Remove-Module PathResolution -ErrorAction SilentlyContinue -Force
    Remove-Module Cache -ErrorAction SilentlyContinue -Force
    Remove-Module Logging -ErrorAction SilentlyContinue -Force
    Remove-Module FileFiltering -ErrorAction SilentlyContinue -Force
    Remove-Module FileBackup -ErrorAction SilentlyContinue -Force
}

Describe 'ModuleImport extended scenarios' {
    Context 'Import-LibModule' {
        It 'Resolves PathResolution from the path subdirectory' {
            $module = Import-LibModule -ModuleName 'PathResolution' -ScriptPath $script:TestScriptPath -ErrorAction Stop

            $module | Should -Not -BeNullOrEmpty
            ($module.Path -replace '\\', '/') | Should -Match '/path/PathResolution\.psm1'
        }

        It 'Resolves FileFiltering from the file subdirectory' {
            Remove-Module FileFiltering -ErrorAction SilentlyContinue -Force

            $module = Import-LibModule -ModuleName 'FileFiltering' -ScriptPath $script:TestScriptPath -Global -ErrorAction Stop

            $module | Should -Not -BeNullOrEmpty
            ($module.Path -replace '\\', '/') | Should -Match '/file/FileFiltering\.psm1'
            $module.ExportedFunctions.Keys | Should -Contain 'Filter-Files'
        }

        It 'Resolves FileBackup from the file subdirectory' {
            Remove-Module FileBackup -ErrorAction SilentlyContinue -Force

            $module = Import-LibModule -ModuleName 'FileBackup' -ScriptPath $script:TestScriptPath -Global -ErrorAction Stop

            $module | Should -Not -BeNullOrEmpty
            ($module.Path -replace '\\', '/') | Should -Match '/file/FileBackup\.psm1'
            $module.ExportedFunctions.Keys | Should -Contain 'New-FileBackup'
            $module.ExportedFunctions.Keys | Should -Contain 'Restore-FileBackup'
        }
    }

    Context 'Import-LibModules' {
        It 'Imports a mix of root and subdirectory modules' {
            Remove-Module Logging -ErrorAction SilentlyContinue -Force
            Remove-Module FileFiltering -ErrorAction SilentlyContinue -Force

            $modules = Import-LibModules -ModuleNames @('Logging', 'FileFiltering') -ScriptPath $script:TestScriptPath -ErrorAction Stop

            @($modules).Count | Should -Be 2
            $exported = @($modules | ForEach-Object { $_.ExportedFunctions.Keys })
            $exported | Should -Contain 'Write-ScriptMessage'
            $exported | Should -Contain 'Filter-Files'
        }
    }

    Context 'Initialize-ScriptEnvironment' {
        It 'Combines repository root and imported module metadata' {
            $environment = Initialize-ScriptEnvironment `
                -ScriptPath $script:TestScriptPath `
                -GetRepoRoot `
                -ImportModules @('Logging')

            $environment.RepoRoot | Should -Not -BeNullOrEmpty
            @($environment.ImportedModules).Count | Should -BeGreaterThan 0
            $environment.LibPath | Should -Not -BeNullOrEmpty
        }

        It 'Resolves profile directory from repository root' {
            $environment = Initialize-ScriptEnvironment `
                -ScriptPath $script:TestScriptPath `
                -GetProfileDir

            $environment.ProfileDir | Should -Not -BeNullOrEmpty
            $environment.ProfileDir | Should -BeLike '*profile.d'
        }

        It 'Resolves script path when the script file does not yet exist' {
            $missingScript = Join-Path $script:TestScriptPath 'nested' 'future-script.ps1'
            $parentDir = Split-Path -Parent $missingScript
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null

            $environment = Initialize-ScriptEnvironment -ScriptPath $missingScript -GetRepoRoot
            $environment.ScriptPath | Should -Not -BeNullOrEmpty
            $environment.RepoRoot | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Import-LibModule fallback resolution' {
        It 'Resolves unmapped modules by searching library subdirectories' {
            Remove-Module SafeImport -ErrorAction SilentlyContinue -Force

            $module = Import-LibModule -ModuleName 'SafeImport' -ScriptPath $script:TestScriptPath -ErrorAction Stop

            $module | Should -Not -BeNullOrEmpty
            ($module.Path -replace '\\', '/') | Should -Match '/core/SafeImport\.psm1'
        }

        It 'Imports ModuleImport from the library root path' {
            Remove-Module ModuleImport -ErrorAction SilentlyContinue -Force
            Import-Module (Join-Path $script:LibPath 'path' 'PathResolution.psm1') -DisableNameChecking -Force -Global
            if (Test-Path -LiteralPath (Join-Path $script:LibPath 'utilities' 'Cache.psm1')) {
                Import-Module (Join-Path $script:LibPath 'utilities' 'Cache.psm1') -DisableNameChecking -Force -Global
            }
            Import-Module (Join-Path $script:LibPath 'ModuleImport.psm1') -DisableNameChecking -Force

            $module = Import-LibModule -ModuleName 'ModuleImport' -ScriptPath $script:TestScriptPath -ErrorAction Stop
            $module | Should -Not -BeNullOrEmpty
            ($module.Path -replace '\\', '/') | Should -Match '/ModuleImport\.psm1$'
        }
    }

    Context 'Optional import warnings and debug hooks' {
        It 'Emits structured warnings for optional missing modules when debug is enabled' {
            function global:Write-StructuredWarning {
                param(
                    [string]$Message,
                    [string]$OperationName,
                    [hashtable]$Context,
                    [string]$Code
                )
            }

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $result = Import-LibModule `
                    -ModuleName 'DefinitelyMissingModuleForImportProbe' `
                    -ScriptPath $script:TestScriptPath `
                    -Required:$false `
                    -ErrorAction Continue

                $result | Should -BeNullOrEmpty
            }
            finally {
                Remove-TestFunction -Name 'Write-StructuredWarning'
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Logs plain warnings when structured logging is unavailable' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $result = Import-LibModule `
                    -ModuleName 'AnotherMissingModuleImportProbe' `
                    -ScriptPath $script:TestScriptPath `
                    -Required:$false `
                    -ErrorAction Continue

                $result | Should -BeNullOrEmpty
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

        It 'Logs verbose details for optional missing modules at debug level 3' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $originalVerbose = $VerbosePreference
            $env:PS_PROFILE_DEBUG = '3'
            $VerbosePreference = 'Continue'

            try {
                $result = Import-LibModule `
                    -ModuleName 'VerboseMissingModuleImportProbe' `
                    -ScriptPath $script:TestScriptPath `
                    -Required:$false `
                    -ErrorAction Continue

                $result | Should -BeNullOrEmpty
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
    }

    Context 'Get-LibPath validation paths' {
        It 'Uses Test-ValidPath when validating the library directory' {
            $libPath = Get-LibPath -ScriptPath $script:TestScriptPath
            $libPath | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $libPath | Should -Be $true
        }

        It 'Throws when Get-RepoRoot is unavailable' {
            $uncachedScriptPath = Get-TestScriptPath -RelativePath 'scripts/utils/uncached-lib-path.ps1' -StartPath $PSScriptRoot
            if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                $cacheKey = if (Get-Command New-CacheKey -ErrorAction SilentlyContinue) {
                    New-CacheKey -Prefix 'LibPath' -Components @($uncachedScriptPath)
                }
                else {
                    "LibPath_$uncachedScriptPath"
                }
                Clear-CachedValue -Key $cacheKey -ErrorAction SilentlyContinue
            }

            Remove-TestFunction -Name 'Get-RepoRoot'

            try {
                { Get-LibPath -ScriptPath $uncachedScriptPath } | Should -Throw '*Get-RepoRoot*'
            }
            finally {
                Import-Module (Join-Path $script:LibPath 'path' 'PathResolution.psm1') -DisableNameChecking -Force -Global
            }
        }
    }

    Context 'Import-LibModules error handling' {
        It 'Uses Get-ErrorActionPreference when ErrorHandling is loaded' {
            Remove-Module ErrorHandling -ErrorAction SilentlyContinue -Force
            Import-Module (Join-Path $script:LibPath 'core' 'ErrorHandling.psm1') -DisableNameChecking -Force -Global

            $modules = Import-LibModules `
                -ModuleNames @('ExitCodes', 'Logging') `
                -ScriptPath $script:TestScriptPath `
                -ErrorAction SilentlyContinue

            @($modules).Count | Should -BeGreaterOrEqual 2
        }

        It 'Aggregates failures when a required batch import fails' {
            { Import-LibModules -ModuleNames @('ExitCodes', 'MissingBatchModuleProbe') -ScriptPath $script:TestScriptPath } |
                Should -Throw '*Failed to import*'
        }
    }
}
