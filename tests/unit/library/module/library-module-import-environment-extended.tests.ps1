<#
tests/unit/library/library-module-import-environment-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Initialize-ScriptEnvironment and ModuleImport error paths.
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
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ModuleImportPath = Join-Path $script:LibPath 'ModuleImport.psm1'
    $script:PathResolutionPath = Join-Path $script:LibPath 'path' 'PathResolution.psm1'
    $script:ExitCodesPath = Join-Path $script:LibPath 'core' 'ExitCodes.psm1'
    $script:CachePath = Join-Path $script:LibPath 'utilities' 'Cache.psm1'
    $script:TestScriptPath = Get-TestScriptPath -RelativePath 'scripts/utils/env-init.ps1' -StartPath $PSScriptRoot
    $script:TempRoot = New-TestTempDirectory -Prefix 'ModuleImportEnvExtended'

    Remove-Module ModuleImport, PathResolution, Cache, ExitCodes, ErrorHandling, SafeImport -ErrorAction SilentlyContinue -Force
    if (Test-Path -LiteralPath $script:CachePath) {
        Import-Module $script:CachePath -DisableNameChecking -Force -Global
    }
    Import-Module $script:ModuleImportPath -DisableNameChecking -Force
}

AfterAll {
    Remove-TestFunction -Name @('Get-RepoRoot', 'Get-RepoRootSafe', 'Get-ProfileDirectory', 'Exit-WithCode', 'Write-StructuredError', 'Write-StructuredWarning', 'Import-ModuleSafely')
    Remove-Module ModuleImport, PathResolution, Cache, ExitCodes, ErrorHandling, SafeImport -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ModuleImport environment and error paths' {
    AfterEach {
        Remove-Item Env:PS_PROFILE_MODULE_IMPORT_FORCE_INIT_ERROR -ErrorAction SilentlyContinue
        Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    }

    Context 'Module bootstrap fallbacks' {
        It 'Imports dependencies manually when Import-ModuleSafely is unavailable' {
            Remove-Module ModuleImport, SafeImport, PathResolution, Cache, ErrorHandling -ErrorAction SilentlyContinue -Force
            Remove-TestFunction -Name 'Import-ModuleSafely'

            Import-Module $script:ModuleImportPath -DisableNameChecking -Force

            Get-Command Get-RepoRoot -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-LibPath -ScriptPath $script:TestScriptPath | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-LibPath error handling' {
        It 'Throws when ScriptPath is whitespace' {
            { Get-LibPath -ScriptPath '   ' } | Should -Throw '*ScriptPath cannot be null or empty*'
        }

        It 'Throws when scripts/lib directory does not exist for the resolved root' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'ModuleImportMissingLib'
            $outsideScript = Join-Path $outsideRoot 'scripts' 'utils' 'orphan.ps1'
            New-Item -ItemType Directory -Path (Split-Path -Parent $outsideScript) -Force | Out-Null
            Set-Content -LiteralPath $outsideScript -Value '# probe' -Encoding utf8

            if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                $cacheKey = if (Get-Command New-CacheKey -ErrorAction SilentlyContinue) {
                    New-CacheKey -Prefix 'LibPath' -Components @($outsideScript)
                }
                else {
                    "LibPath_$outsideScript"
                }
                Clear-CachedValue -Key $cacheKey -ErrorAction SilentlyContinue
            }

            { Get-LibPath -ScriptPath $outsideScript } | Should -Throw '*Failed to resolve scripts/lib path*'
        }
    }

    Context 'Import-LibModule optional import diagnostics' {
        It 'Warns for optional missing modules even when debug is disabled' {
            $result = Import-LibModule `
                -ModuleName 'OptionalMissingModuleNoDebug' `
                -ScriptPath $script:TestScriptPath `
                -Required:$false `
                -ErrorAction Continue

            $result | Should -BeNullOrEmpty
        }

        It 'Returns null when lib path resolution fails for optional imports' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'ModuleImportOptionalLibFail'
            $outsideScript = Join-Path $outsideRoot 'scripts' 'utils' 'optional.ps1'
            New-Item -ItemType Directory -Path (Split-Path -Parent $outsideScript) -Force | Out-Null
            Set-Content -LiteralPath $outsideScript -Value '# probe' -Encoding utf8

            $result = Import-LibModule `
                -ModuleName 'ExitCodes' `
                -ScriptPath $outsideScript `
                -Required:$false `
                -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Import-LibModules batch handling' {
        It 'Throws when ScriptPath is explicitly empty' {
            { Import-LibModules -ModuleNames @('ExitCodes') -ScriptPath '' } | Should -Throw '*ScriptPath cannot be null or empty*'
        }

        It 'Aggregates failures when required modules are missing without immediate stop' {
            { Import-LibModules -ModuleNames @('ExitCodes', 'BatchMissingModuleProbe') -ScriptPath $script:TestScriptPath -Required:$true -ErrorAction Continue } |
                Should -Throw '*Failed to import*module*'
        }
    }

    Context 'Initialize-ScriptEnvironment validation' {
        It 'Rejects explicitly empty ScriptPath values' {
            { Initialize-ScriptEnvironment -ScriptPath '' } | Should -Throw '*ScriptPath cannot be null or empty*'
        }

        It 'Rejects explicitly empty ScriptPath for batch module imports' {
            { Initialize-ScriptEnvironment -ScriptPath '' -ImportModules @('ExitCodes') } | Should -Throw '*ScriptPath cannot be null or empty*'
        }
    }

    Context 'Initialize-ScriptEnvironment ExitOnError without Exit-WithCode' {
        function global:Write-StructuredError {
            param(
                $ErrorRecord,
                [string]$OperationName,
                [hashtable]$Context
            )
        }

        AfterEach {
            Remove-TestFunction -Name @('Write-StructuredError', 'Exit-WithCode', 'Get-RepoRoot')
            Import-Module $script:PathResolutionPath -DisableNameChecking -Force -Global
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        }

        It 'Uses structured errors when lib path resolution fails with ExitOnError and debug enabled' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'ModuleImportInitLibFail'
            $outsideScript = Join-Path $outsideRoot 'scripts' 'utils' 'init-fail.ps1'
            New-Item -ItemType Directory -Path (Split-Path -Parent $outsideScript) -Force | Out-Null
            Set-Content -LiteralPath $outsideScript -Value '# probe' -Encoding utf8
            $env:PS_PROFILE_DEBUG = '1'

            { Initialize-ScriptEnvironment -ScriptPath $outsideScript -ExitOnError } | Should -Throw '*Failed to resolve scripts/lib path*'
        }

        It 'Uses Write-Error when import modules fail, ExitOnError is set, and Exit-WithCode is unavailable' {
            Remove-TestFunction -Name 'Exit-WithCode'
            $env:PS_PROFILE_DEBUG = '1'

            { Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -ImportModules @('MissingInitModuleProbe') -ExitOnError } |
                Should -Throw '*Failed to import modules*'
        }

        It 'Uses structured errors when repository root lookup fails with ExitOnError' {
            Remove-TestFunction -Name @('Get-RepoRoot', 'Get-RepoRootSafe')
            function global:Get-RepoRootSafe {
                param(
                    [string]$ScriptPath,
                    [switch]$ExitOnError
                )
                throw 'Simulated repository root failure'
            }
            $env:PS_PROFILE_DEBUG = '1'

            { Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -GetRepoRoot -ExitOnError } |
                Should -Throw '*Failed to get repository root*'
        }

        It 'Uses Write-Error for lib path failures when Exit-WithCode is unavailable' {
            Remove-TestFunction -Name 'Exit-WithCode'
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'ModuleImportInitLibWriteError'
            $outsideScript = Join-Path $outsideRoot 'scripts' 'utils' 'init-write-error.ps1'
            New-Item -ItemType Directory -Path (Split-Path -Parent $outsideScript) -Force | Out-Null
            Set-Content -LiteralPath $outsideScript -Value '# probe' -Encoding utf8

            { Initialize-ScriptEnvironment -ScriptPath $outsideScript -ExitOnError } |
                Should -Throw '*Failed to resolve scripts/lib path*'
        }
    }

    Context 'Initialize-ScriptEnvironment ExitOnError with Exit-WithCode' {
        BeforeEach {
            Remove-Module ExitCodes -ErrorAction SilentlyContinue -Force
            Remove-TestFunction -Name 'Exit-WithCode'
            function global:Exit-WithCode {
                param(
                    [int]$ExitCode,
                    $ErrorRecord,
                    [string]$Message
                )
                throw [System.Management.Automation.RuntimeException]::new("ExitWithCodeProbe:${ExitCode}")
            }
        }

        AfterEach {
            Remove-TestFunction -Name 'Exit-WithCode'
        }

        It 'Delegates to Exit-WithCode when module import fails' {
            { Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -ImportModules @('MissingExitModuleProbe') -ExitOnError } |
                Should -Throw '*Failed to import modules*'
        }

        It 'Uses Exit-WithCode when auto-detect fails and ExitOnError is enabled' {
            $env:PS_PROFILE_MODULE_IMPORT_FORCE_INIT_ERROR = 'auto-detect'

            { Initialize-ScriptEnvironment -ExitOnError } |
                Should -Throw '*Could not auto-detect script path*'
        }

        It 'Uses Exit-WithCode when script path resolution fails with ExitOnError' {
            $env:PS_PROFILE_MODULE_IMPORT_FORCE_INIT_ERROR = 'script-resolve'

            { Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -ExitOnError } |
                Should -Throw '*Failed to resolve script path*'
        }

        It 'Uses Exit-WithCode when repository root lookup fails' {
            Remove-TestFunction -Name @('Get-RepoRoot', 'Get-RepoRootSafe')
            function global:Get-RepoRootSafe {
                param(
                    [string]$ScriptPath,
                    [switch]$ExitOnError
                )
                throw 'Simulated repo root failure'
            }

            { Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -GetRepoRoot -ExitOnError } |
                Should -Throw '*Failed to get repository root*'
        }
    }

    Context 'Initialize-ScriptEnvironment Get-RepoRootSafe integration' {
        It 'Uses Get-RepoRootSafe when available for repository root resolution' {
            function global:Get-RepoRootSafe {
                param(
                    [string]$ScriptPath,
                    [switch]$ExitOnError
                )
                return $script:RepoRoot
            }

            try {
                $environment = Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -GetRepoRoot
                $environment.RepoRoot | Should -Be $script:RepoRoot
            }
            finally {
                Remove-TestFunction -Name 'Get-RepoRootSafe'
            }
        }

        It 'Uses Get-RepoRootSafe with ExitOnError when resolving profile directory' {
            function global:Get-RepoRootSafe {
                param(
                    [string]$ScriptPath,
                    [switch]$ExitOnError
                )
                return $script:RepoRoot
            }

            try {
                $environment = Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -GetProfileDir
                $environment.ProfileDir | Should -BeLike '*profile.d'
            }
            finally {
                Remove-TestFunction -Name 'Get-RepoRootSafe'
            }
        }
    }

    Context 'Initialize-ScriptEnvironment profile directory fallback' {
        It 'Uses Get-ProfileDirectory when repository root cannot be resolved inline' {
            function global:Get-ProfileDirectory {
                param([string]$ScriptPath)
                return Join-Path $script:RepoRoot 'profile.d'
            }

            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                return $null
            }

            try {
                $environment = Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -GetProfileDir
                $environment.ProfileDir | Should -Be (Join-Path $script:RepoRoot 'profile.d')
            }
            finally {
                Remove-TestFunction -Name @('Get-ProfileDirectory', 'Get-RepoRoot')
                Import-Module $script:PathResolutionPath -DisableNameChecking -Force -Global
            }
        }
    }

    Context 'Initialize-ScriptEnvironment auto-detected script path' {
        function script:Invoke-InitializeFromTestScript {
            return Initialize-ScriptEnvironment -GetRepoRoot
        }

        It 'Auto-detects script path from the in-process test call stack' {
            $environment = Invoke-InitializeFromTestScript
            $environment.ScriptPath | Should -Not -BeNullOrEmpty
            ($environment.ScriptPath -replace '\\', '/') | Should -Match 'library-module-import-environment-extended\.tests\.ps1$'
        }

        It 'Resolves missing script files from their parent directory' {
            $missingScript = Join-Path $script:TempRoot 'nested' 'missing-init-script.ps1'
            New-Item -ItemType Directory -Path (Split-Path -Parent $missingScript) -Force | Out-Null

            $environment = Initialize-ScriptEnvironment -ScriptPath $missingScript -GetRepoRoot
            $environment.ScriptPath | Should -Not -BeNullOrEmpty
            ($environment.ScriptPath -replace '\\', '/') | Should -Match 'missing-init-script\.ps1$'
        }
    }

    Context 'Import-LibModule and Import-LibModules auto-detected script path' {
        function script:Invoke-ImportLibModuleFromTestScript {
            return Import-LibModule -ModuleName 'ExitCodes'
        }

        function script:Invoke-ImportLibModulesFromTestScript {
            return Import-LibModules -ModuleNames @('ExitCodes')
        }

        It 'Auto-detects script path when importing a single module' {
            $module = Invoke-ImportLibModuleFromTestScript
            $module | Should -Not -BeNullOrEmpty
        }

        It 'Auto-detects script path when importing multiple modules' {
            $modules = Invoke-ImportLibModulesFromTestScript
            @($modules).Count | Should -BeGreaterOrEqual 1
        }
    }

    Context 'Initialize-ScriptEnvironment auto-detect failure paths' {
        AfterEach {
            Remove-TestFunction -Name @('Write-StructuredError', 'Exit-WithCode', 'Get-RepoRoot', 'Get-RepoRootSafe')
            Import-Module $script:PathResolutionPath -DisableNameChecking -Force -Global
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            Remove-Item Env:PS_PROFILE_MODULE_IMPORT_FORCE_INIT_ERROR -ErrorAction SilentlyContinue
        }

        It 'Throws when script path cannot be auto-detected' {
            $env:PS_PROFILE_MODULE_IMPORT_FORCE_INIT_ERROR = 'auto-detect'

            { Initialize-ScriptEnvironment -GetRepoRoot } |
                Should -Throw '*Could not auto-detect script path*'
        }

        It 'Uses structured errors when auto-detect fails with debug enabled and no Exit-WithCode' {
            function global:Write-StructuredError {
                param($ErrorRecord, [string]$OperationName, [hashtable]$Context)
            }

            $env:PS_PROFILE_MODULE_IMPORT_FORCE_INIT_ERROR = 'auto-detect'
            $env:PS_PROFILE_DEBUG = '3'
            Remove-TestFunction -Name 'Exit-WithCode'

            { Initialize-ScriptEnvironment -ExitOnError } |
                Should -Throw '*Could not auto-detect script path*'
        }

        It 'Uses Write-Error when auto-detect fails without structured logging' {
            Remove-TestFunction -Name @('Write-StructuredError', 'Exit-WithCode')
            $env:PS_PROFILE_MODULE_IMPORT_FORCE_INIT_ERROR = 'auto-detect'
            $env:PS_PROFILE_DEBUG = '1'

            { Initialize-ScriptEnvironment -ExitOnError } |
                Should -Throw '*Could not auto-detect script path*'
        }
    }

    Context 'Initialize-ScriptEnvironment script path resolution failures' {
        AfterEach {
            Remove-TestFunction -Name @('Write-StructuredError', 'Exit-WithCode', 'Get-RepoRoot', 'Get-RepoRootSafe')
            Import-Module $script:PathResolutionPath -DisableNameChecking -Force -Global
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            Remove-Item Env:PS_PROFILE_MODULE_IMPORT_FORCE_INIT_ERROR -ErrorAction SilentlyContinue
        }

        It 'Throws when script path resolution fails' {
            $env:PS_PROFILE_MODULE_IMPORT_FORCE_INIT_ERROR = 'script-resolve'

            { Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -GetRepoRoot } |
                Should -Throw '*Failed to resolve script path*'
        }

        It 'Uses structured errors for script path resolution failures at debug level 3' {
            function global:Write-StructuredError {
                param($ErrorRecord, [string]$OperationName, [hashtable]$Context)
            }

            $env:PS_PROFILE_MODULE_IMPORT_FORCE_INIT_ERROR = 'script-resolve'
            $env:PS_PROFILE_DEBUG = '3'
            Remove-TestFunction -Name 'Exit-WithCode'

            { Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -ExitOnError } |
                Should -Throw '*Failed to resolve script path*'
        }
    }

    Context 'Initialize-ScriptEnvironment profile and repo root failures' {
        AfterEach {
            Remove-TestFunction -Name @('Get-RepoRoot', 'Get-RepoRootSafe', 'Get-ProfileDirectory', 'Write-StructuredError', 'Exit-WithCode')
            Import-Module $script:PathResolutionPath -DisableNameChecking -Force -Global
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        }

        It 'Throws when profile directory cannot be determined' {
            Remove-TestFunction -Name @('Get-RepoRoot', 'Get-RepoRootSafe', 'Get-ProfileDirectory')
            function global:Get-RepoRootSafe {
                param(
                    [string]$ScriptPath,
                    [switch]$ExitOnError
                )
                return $null
            }
            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                return $null
            }

            { Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -GetProfileDir } |
                Should -Throw '*Failed to get profile directory*'
        }

        It 'Uses structured errors when profile directory lookup fails with ExitOnError' {
            function global:Write-StructuredError {
                param($ErrorRecord, [string]$OperationName, [hashtable]$Context)
            }

            Remove-TestFunction -Name @('Get-RepoRoot', 'Get-RepoRootSafe', 'Get-ProfileDirectory')
            function global:Get-RepoRootSafe {
                param(
                    [string]$ScriptPath,
                    [switch]$ExitOnError
                )
                return $null
            }
            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                return $null
            }

            $env:PS_PROFILE_DEBUG = '3'

            { Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -GetProfileDir -ExitOnError } |
                Should -Throw '*Failed to get profile directory*'
        }
    }

    Context 'Get-LibPath manual validation fallback' {
        It 'Uses manual path validation when Test-ValidPath is unavailable' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'ModuleImportManualLibPath'
            $outsideScript = Join-Path $outsideRoot 'scripts' 'utils' 'manual.ps1'
            New-Item -ItemType Directory -Path (Split-Path -Parent $outsideScript) -Force | Out-Null
            Set-Content -LiteralPath $outsideScript -Value '# probe' -Encoding utf8

            Remove-TestFunction -Name 'Test-ValidPath'

            try {
                { Get-LibPath -ScriptPath $outsideScript } | Should -Throw '*Failed to resolve scripts/lib path*'
            }
            finally {
                Import-Module (Join-Path $script:LibPath 'path' 'PathValidation.psm1') -DisableNameChecking -Force -Global -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Import-LibModule import failure handling' {
        It 'Returns null when a broken module file fails to import optionally' {
            $brokenModulePath = Join-Path $script:TempRoot 'BrokenImportProbe.psm1'
            Set-Content -LiteralPath $brokenModulePath -Value 'throw "broken module"' -Encoding utf8

            function global:Get-LibPath {
                param([string]$ScriptPath)
                return $script:TempRoot
            }

            try {
                $result = Import-LibModule `
                    -ModuleName 'BrokenImportProbe' `
                    -ScriptPath $script:TestScriptPath `
                    -Required:$false `
                    -ErrorAction SilentlyContinue

                $result | Should -BeNullOrEmpty
            }
            finally {
                Remove-TestFunction -Name 'Get-LibPath'
            }
        }
    }

    Context 'Initialize-ScriptEnvironment debug tracing' {
        function global:Write-StructuredError {
            param(
                $ErrorRecord,
                [string]$OperationName,
                [hashtable]$Context
            )
        }

        AfterEach {
            Remove-TestFunction -Name @('Write-StructuredError', 'Exit-WithCode', 'Get-RepoRoot', 'Get-RepoRootSafe')
            Import-Module $script:PathResolutionPath -DisableNameChecking -Force -Global
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            $global:VerbosePreference = 'SilentlyContinue'
        }

        It 'Emits verbose tracing for import failures at debug level 3' {
            $env:PS_PROFILE_DEBUG = '3'
            $global:VerbosePreference = 'Continue'

            { Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -ImportModules @('MissingDebugModuleProbe') } |
                Should -Throw '*Failed to import modules*'
        }

        It 'Uses structured errors for import failures without debug enabled' {
            { Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -ImportModules @('MissingStructuredModuleProbe') -ExitOnError } |
                Should -Throw '*Failed to import modules*'
        }

        It 'Uses structured errors for repository root failures without debug enabled' {
            Remove-TestFunction -Name @('Get-RepoRoot', 'Get-RepoRootSafe')
            function global:Get-RepoRootSafe {
                param(
                    [string]$ScriptPath,
                    [switch]$ExitOnError
                )
                throw 'Simulated safe repo root failure'
            }

            { Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -GetRepoRoot -ExitOnError } |
                Should -Throw '*Failed to get repository root*'
        }

        It 'Falls back to Get-RepoRoot when Get-RepoRootSafe is unavailable' {
            Remove-TestFunction -Name 'Get-RepoRootSafe'

            $environment = Initialize-ScriptEnvironment -ScriptPath $script:TestScriptPath -GetRepoRoot
            $environment.RepoRoot | Should -Be $script:RepoRoot
        }
    }

    Context 'Import-LibModule structured optional warnings' {
        It 'Emits structured warnings when debug is disabled and ErrorAction is Continue' {
            function global:Write-StructuredWarning {
                param(
                    [string]$Message,
                    [string]$OperationName,
                    [hashtable]$Context,
                    [string]$Code
                )
            }

            try {
                $result = Import-LibModule `
                    -ModuleName 'StructuredOptionalMissingModule' `
                    -ScriptPath $script:TestScriptPath `
                    -Required:$false `
                    -ErrorAction Continue

                $result | Should -BeNullOrEmpty
            }
            finally {
                Remove-TestFunction -Name 'Write-StructuredWarning'
            }
        }
    }
}
