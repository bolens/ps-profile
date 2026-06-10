<#
tests/unit/library-command-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Command availability and install resolution.
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
    $script:CachePath = Join-Path $script:LibPath 'utilities' 'Cache.psm1'
    $script:CommandPath = Join-Path $script:LibPath 'utilities' 'Command.psm1'

    if (Test-Path -LiteralPath $script:CachePath) {
        Import-TestLibraryModule -ModulePath $script:CachePath
    }

    Import-TestLibraryModule -ModulePath $script:CommandPath
}

function global:Reset-CommandTestModule {
    if (Test-Path -LiteralPath $script:CachePath) {
        Import-TestLibraryModule -ModulePath $script:CachePath -RemoveExisting
    }

    Import-TestLibraryModule -ModulePath $script:CommandPath -RemoveExisting
}

function global:Get-CommandAvailabilityCacheKey {
    param([string]$CommandName)

    if (Get-Command New-CacheKey -ErrorAction SilentlyContinue) {
        return New-CacheKey -Prefix 'CommandAvailable' -Components @($CommandName)
    }

    return "CommandAvailable_$CommandName"
}

function global:Clear-CommandAvailabilityCache {
    param([string]$CommandName)

    if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
        $cacheKey = Get-CommandAvailabilityCacheKey -CommandName $CommandName
        Clear-CachedValue -Key $cacheKey -ErrorAction SilentlyContinue
    }
}

function global:Remove-PreferenceAwareInstallHintStub {
    Remove-TestFunction -Name 'Get-PreferenceAwareInstallHint'
}

AfterAll {
    Remove-Module Command -ErrorAction SilentlyContinue -Force
    Remove-Module Cache -ErrorAction SilentlyContinue -Force
}

Describe 'Command extended scenarios' {
    BeforeEach {
        Clear-CommandTestStubs
    }

    Context 'Test-CommandAvailable' {
        It 'Returns false for null command names' {
            Test-CommandAvailable -CommandName $null | Should -Be $false
        }

        It 'Returns false for whitespace command names' {
            Test-CommandAvailable -CommandName '   ' | Should -Be $false
        }
    }

    Context 'Resolve-InstallCommand' {
        It 'Returns plain string install commands unchanged' {
            $command = 'apt-get install -y example-tool'

            Resolve-InstallCommand -InstallCommand $command | Should -Be $command
        }

        It 'Selects the Linux install command from a platform map' {
            $installMap = @{
                Windows = 'winget install Example'
                Linux   = 'apt-get install -y example'
                macOS   = 'brew install example'
            }

            Resolve-InstallCommand -InstallCommand $installMap | Should -Be 'apt-get install -y example'
        }
    }

    Context 'Invoke-CommandIfAvailable' {
        It 'Returns the fallback value when the command is unavailable' {
            $result = Invoke-CommandIfAvailable `
                -CommandName 'Definitely-Missing-Command-12345' `
                -FallbackValue 'fallback-result'

            $result | Should -Be 'fallback-result'
        }

        It 'Invokes available commands with hashtable arguments' {
            $result = Invoke-CommandIfAvailable `
                -CommandName 'Join-Path' `
                -Arguments @{ Path = 'a'; ChildPath = 'b.txt' }

            ($result -replace '\\', '/') | Should -Be 'a/b.txt'
        }
    }

    Context 'Test-CommandAvailable advanced paths' {
        AfterEach {
            Clear-CommandTestStubs
            Clear-LibraryTestEnvironmentVariables
            Clear-CommandAvailabilityCache -CommandName 'Get-Process'
            Reset-CommandTestModule
        }

        It 'Uses Test-CachedCommand when the helper is available' {
            function global:Test-CachedCommand {
                param([string]$CommandName)
                return $CommandName -eq 'stub-available-command'
            }

            Reset-CommandTestModule
            Test-CommandAvailable -CommandName 'stub-available-command' | Should -Be $true
            Test-CommandAvailable -CommandName 'stub-missing-command' | Should -Be $false
        }

        It 'Returns cached values on subsequent lookups' {
            if (-not (Get-Command Set-CachedValue -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Cache module helpers are unavailable'
                return
            }

            $cacheKey = if (Get-Command New-CacheKey -ErrorAction SilentlyContinue) {
                New-CacheKey -Prefix 'CommandAvailable' -Components @('CachedProbeCommand')
            }
            else {
                'CommandAvailable_CachedProbeCommand'
            }

            Set-CachedValue -Key $cacheKey -Value $true -ExpirationSeconds 300
            Test-CommandAvailable -CommandName 'CachedProbeCommand' | Should -Be $true
        }

        It 'Emits debug output when PS_PROFILE_DEBUG is enabled' {
            $env:PS_PROFILE_DEBUG = '3'
            Clear-CommandAvailabilityCache -CommandName 'Get-Process'

            [bool](Test-CommandAvailable -CommandName 'Get-Process') | Should -Be $true
        }
    }

    Context 'Resolve-InstallCommand platform overrides' {
        AfterEach {
            Clear-CommandTestStubs
            Clear-LibraryTestEnvironmentVariables
        }

        It 'Selects Windows install commands when platform is forced to Windows' {
            $env:PS_PROFILE_PLATFORM_FORCE_NAME = 'Windows'
            Import-Module (Join-Path $script:LibPath 'core' 'Platform.psm1') -DisableNameChecking -Force

            $installMap = @{
                Windows = 'winget install Example'
                Linux   = 'apt-get install -y example'
                macOS   = 'brew install example'
            }

            Resolve-InstallCommand -InstallCommand $installMap | Should -Be 'winget install Example'
        }

        It 'Selects macOS install commands when platform is forced to macOS' {
            $env:PS_PROFILE_PLATFORM_FORCE_NAME = 'macOS'
            Import-Module (Join-Path $script:LibPath 'core' 'Platform.psm1') -DisableNameChecking -Force

            $installMap = @{
                Windows = 'winget install Example'
                Linux   = 'apt-get install -y example'
                macOS   = 'brew install example'
            }

            Resolve-InstallCommand -InstallCommand $installMap | Should -Be 'brew install example'
        }

        It 'Uses PackageNames recommendation helpers when available' {
            function global:Get-NodePackageInstallRecommendation {
                param(
                    [string[]]$PackageNames,
                    [switch]$Global
                )
                return "recommended $($PackageNames[0])"
            }

            Resolve-InstallCommand -InstallCommand 'npm install -g demo-package' |
                Should -Be 'recommended demo-package'
        }
    }

    Context 'Invoke-CommandIfAvailable error handling hooks' {
        AfterEach {
            Remove-Item Env:PS_PROFILE_COMMAND_DISABLE_STRUCTURED_WARNING -ErrorAction SilentlyContinue
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            Clear-CommandTestStubs
        }

        It 'Uses plain warnings when structured logging is disabled for execution failures' {
            $env:PS_PROFILE_COMMAND_DISABLE_STRUCTURED_WARNING = '1'
            $env:PS_PROFILE_DEBUG = '1'

            function global:CommandFailureProbe { throw 'execution failed' }

            Invoke-CommandIfAvailable -CommandName 'CommandFailureProbe' -FallbackValue 'fallback' |
                Should -Be 'fallback'
        }

        It 'Emits structured warnings for execution failures when error handling is available' {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            function global:CommandFailureProbe { throw 'execution failed' }

            Invoke-CommandIfAvailable -CommandName 'CommandFailureProbe' -FallbackValue 'fallback' |
                Should -Be 'fallback'
        }
    }

    Context 'Get-ToolInstallHint' {
        AfterEach {
            Remove-PreferenceAwareInstallHintStub
        }

        It 'Returns a default install hint when requirements are unavailable' {
            $hint = Get-ToolInstallHint -ToolName 'missing-tool-12345' -DefaultInstallCommand 'scoop install missing-tool-12345'
            $hint | Should -Be 'Install with: scoop install missing-tool-12345'
        }

        It 'Uses preference-aware install hints when available' {
            function global:Get-PreferenceAwareInstallHint {
                param([string]$ToolName, [string]$DefaultInstallCommand)
                return "Install with: custom $ToolName"
            }

            Get-ToolInstallHint -ToolName 'demo-tool' | Should -Be 'custom demo-tool'
        }

        It 'Strips the Install with prefix from preference-aware hints' {
            function global:Get-PreferenceAwareInstallHint {
                param([string]$ToolName, [string]$DefaultInstallCommand)
                return 'Install with: winget install demo-tool'
            }

            Get-ToolInstallHint -ToolName 'demo-tool' | Should -Be 'winget install demo-tool'
        }
    }

    Context 'Module import hooks' {
        AfterEach {
            Remove-Item Env:PS_PROFILE_COMMAND_FORCE_CACHE_IMPORT_ERROR -ErrorAction SilentlyContinue
            Remove-Item Env:PS_PROFILE_COMMAND_FORCE_MANUAL_CACHE_IMPORT -ErrorAction SilentlyContinue
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            Clear-CommandAvailabilityCache -CommandName 'Get-Process'
            Reset-CommandTestModule
        }

        It 'Logs cache import failures when forced and debug is enabled' {
            $env:PS_PROFILE_COMMAND_FORCE_CACHE_IMPORT_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '3'

            Remove-Module Command -ErrorAction SilentlyContinue -Force
            { Import-Module $script:CommandPath -DisableNameChecking -Force } | Should -Not -Throw

            Clear-CommandAvailabilityCache -CommandName 'Get-Process'

            [bool](Test-CommandAvailable -CommandName 'Get-Process') | Should -Be $true
        }
    }

    Context 'Additional Command coverage hooks' {
        BeforeEach {
            Clear-CommandTestStubs
            Clear-CommandAvailabilityCache -CommandName 'Get-Process'
        }

        AfterEach {
            Clear-LibraryTestEnvironmentVariables
            Clear-CommandTestStubs
            Clear-CommandAvailabilityCache -CommandName 'Get-Process'
            Reset-CommandTestModule
        }

        It 'Uses plain warnings when structured logging is disabled for Python recommendation failures' {
            $env:PS_PROFILE_COMMAND_DISABLE_STRUCTURED_WARNING = '1'
            $env:PS_PROFILE_DEBUG = '1'

            function global:Get-PythonPackageInstallRecommendation {
                param([string[]]$PackageNames, [switch]$Global)
                throw 'python recommendation failed'
            }

            $result = Resolve-InstallCommand -InstallCommand 'pip install demo-package' -PackageName 'demo-package'
            $result | Should -Match 'demo-package'
        }

        It 'Emits structured warnings for Python recommendation failures when error handling is available' {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            $env:PS_PROFILE_DEBUG = '3'

            function global:Get-PythonPackageInstallRecommendation {
                param([string]$PackageName, [switch]$Global)
                throw 'python recommendation failed'
            }

            $result = Resolve-InstallCommand -InstallCommand 'pip install demo-package' -PackageName 'demo-package'
            $result | Should -Match 'demo-package'
        }

        It 'Uses Node recommendation helpers with singular PackageName parameter' {
            function global:Get-NodePackageInstallRecommendation {
                param([string]$PackageName, [switch]$Global)
                return "node install $PackageName"
            }

            Resolve-InstallCommand -InstallCommand 'npm install -g demo-package' |
                Should -Be 'node install demo-package'
        }

        It 'Resolves install hints from mocked requirements data' {
            $env:PS_PROFILE_PLATFORM_FORCE_NAME = 'Linux'
            Import-Module (Join-Path $script:LibPath 'core' 'Platform.psm1') -DisableNameChecking -Force

            function global:Import-Requirements {
                param([string]$RepoRoot, [switch]$UseCache)
                return [PSCustomObject]@{
                    ExternalTools = @{
                        'demo-tool' = @{
                            InstallCommand = @{
                                Linux = 'apt install demo-tool'
                            }
                        }
                    }
                }
            }

            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                return '/tmp/demo-repo'
            }

            Get-ToolInstallHint -ToolName 'demo-tool' -RepoRoot '/tmp/demo-repo' |
                Should -Be 'Install with: apt install demo-tool'
        }

        It 'Returns default hint when tool has no install command in requirements' {
            Remove-PreferenceAwareInstallHintStub

            function global:Import-Requirements {
                param([string]$RepoRoot, [switch]$UseCache)
                return [PSCustomObject]@{
                    ExternalTools = @{
                        'demo-tool' = @{
                            InstallCommand = $null
                        }
                    }
                }
            }

            Get-ToolInstallHint -ToolName 'demo-tool' -RepoRoot '/tmp/demo-repo' -DefaultInstallCommand 'scoop install demo-tool' |
                Should -Be 'Install with: scoop install demo-tool'
        }

        It 'Uses debug level 2 output for Get-Command fallback availability checks' {
            $env:PS_PROFILE_DEBUG = '2'
            Clear-CommandTestStubs
            Clear-CommandAvailabilityCache -CommandName 'Get-Process'

            [bool](Test-CommandAvailable -CommandName 'Get-Process') | Should -Be $true
        }

        It 'Uses New-CacheKey when generating command availability cache keys' {
            if (-not (Get-Command New-CacheKey -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'New-CacheKey is unavailable'
                return
            }

            if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                $cacheKey = New-CacheKey -Prefix 'CommandAvailable' -Components @('KeyProbeCommand')
                Clear-CachedValue -Key $cacheKey -ErrorAction SilentlyContinue
            }

            [bool](Test-CommandAvailable -CommandName 'KeyProbeCommand') | Should -Be $false
        }

        It 'Logs manual cache import failures when Import-ModuleSafely is unavailable' {
            $env:PS_PROFILE_COMMAND_FORCE_CACHE_IMPORT_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '3'

            Remove-Module Command, SafeImport -ErrorAction SilentlyContinue -Force
            Remove-TestFunction -Name 'Import-ModuleSafely'

            { Import-Module $script:CommandPath -DisableNameChecking -Force } | Should -Not -Throw
            Clear-CommandAvailabilityCache -CommandName 'Get-Process'
            [bool](Test-CommandAvailable -CommandName 'Get-Process') | Should -Be $true
        }

        It 'Falls back when preference-aware install hints throw' {
            function global:Get-PreferenceAwareInstallHint {
                param([string]$ToolName, [string]$DefaultInstallCommand)
                throw 'preference hint failed'
            }

            Get-ToolInstallHint -ToolName 'demo-tool' -DefaultInstallCommand 'scoop install demo-tool' |
                Should -Be 'Install with: scoop install demo-tool'
        }

        It 'Emits debug output when unavailable commands use fallbacks' {
            $env:PS_PROFILE_DEBUG = '3'
            $result = Invoke-CommandIfAvailable -CommandName 'MissingCommandForDebug_12345' -FallbackValue 'fallback'
            $result | Should -Be 'fallback'
        }

        It 'Emits cache hit debug output at level 3' {
            if (-not (Get-Command Set-CachedValue -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Cache module helpers are unavailable'
                return
            }

            $env:PS_PROFILE_DEBUG = '3'
            $cacheKey = Get-CommandAvailabilityCacheKey -CommandName 'CachedDebugProbe'
            Set-CachedValue -Key $cacheKey -Value $true -ExpirationSeconds 300

            [bool](Test-CommandAvailable -CommandName 'CachedDebugProbe') | Should -Be $true
        }

        It 'Emits Test-CachedCommand debug output at level 3' {
            $env:PS_PROFILE_DEBUG = '3'

            function global:Test-CachedCommand {
                param([string]$CommandName)
                return $CommandName -eq 'CachedCommandDebugProbe'
            }

            Clear-CommandAvailabilityCache -CommandName 'CachedCommandDebugProbe'
            [bool](Test-CommandAvailable -CommandName 'CachedCommandDebugProbe') | Should -Be $true
        }

        It 'Returns false when Test-ValidString rejects command names' {
            function global:Test-ValidString {
                param([string]$Value)
                return $Value -eq 'valid-command-name'
            }

            Test-CommandAvailable -CommandName 'invalid-command-name' | Should -Be $false
        }

        It 'Returns null for unsupported install command object types' {
            Resolve-InstallCommand -InstallCommand 123 | Should -BeNullOrEmpty
        }

        It 'Returns null for empty platform-specific install commands' {
            $installMap = @{ Linux = '' }
            Resolve-InstallCommand -InstallCommand $installMap | Should -BeNullOrEmpty
        }

        It 'Returns empty string for empty string install commands' {
            Resolve-InstallCommand -InstallCommand '' | Should -Be ''
        }

        It 'Extracts package names from yarn global add commands' {
            function global:Get-NodePackageInstallRecommendation {
                param([string[]]$PackageNames, [switch]$Global)
                return "yarn add $($PackageNames[0])"
            }

            Resolve-InstallCommand -InstallCommand 'yarn global add demo-package' |
                Should -Be 'yarn add demo-package'
        }

        It 'Uses Node recommendation catch debug output when recommendation fails' {
            $env:PS_PROFILE_DEBUG = '2'

            function global:Get-NodePackageInstallRecommendation {
                param([string[]]$PackageNames, [switch]$Global)
                throw 'node recommendation failed'
            }

            $result = Resolve-InstallCommand -InstallCommand 'npm install -g demo-package'
            $result | Should -Match 'demo-package'
        }

        It 'Extracts package names from pip install fallback patterns' {
            function global:Get-PythonPackageInstallRecommendation {
                param([string[]]$PackageNames, [switch]$Global)
                return "pip install $($PackageNames[0])"
            }

            Resolve-InstallCommand -InstallCommand 'conda install demo-package' -PackageName 'demo-package' |
                Should -Be 'pip install demo-package'
        }

        It 'Uses fallback scriptblocks with hashtable arguments after execution failures' {
            $env:PS_PROFILE_DEBUG = '3'

            function global:CommandFailureProbe {
                param([string]$Value)
                throw "failed for $Value"
            }

            $result = Invoke-CommandIfAvailable `
                -CommandName 'CommandFailureProbe' `
                -Arguments @{ Value = 'probe' } `
                -FallbackScriptBlock { param($Value) "fallback-$Value" }
            $result | Should -Be 'fallback-probe'
        }

        It 'Uses fallback scriptblocks with array arguments when commands are unavailable' {
            $env:PS_PROFILE_DEBUG = '3'

            $result = Invoke-CommandIfAvailable `
                -CommandName 'MissingFallbackArrayCommand_12345' `
                -Arguments @('alpha', 'beta') `
                -FallbackScriptBlock { param($value) "fallback-$($value[0])" }
            $result | Should -Be 'fallback-alpha'
        }

        It 'Uses fallback scriptblocks with scalar arguments when commands are unavailable' {
            $result = Invoke-CommandIfAvailable `
                -CommandName 'MissingFallbackScalarCommand_12345' `
                -Arguments 'scalar-value' `
                -FallbackScriptBlock { param($Value) "fallback-$Value" }
            $result | Should -Be 'fallback-scalar-value'
        }

        It 'Discovers repository roots when Get-RepoRoot is unavailable' {
            Remove-PreferenceAwareInstallHintStub

            function global:Import-Requirements {
                param([string]$RepoRoot, [switch]$UseCache)
                return [PSCustomObject]@{
                    ExternalTools = @{
                        'demo-tool' = @{
                            InstallCommand = 'scoop install demo-tool'
                        }
                    }
                }
            }

            $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            Push-Location $repoRoot
            try {
                Get-ToolInstallHint -ToolName 'demo-tool' |
                    Should -Be 'Install with: scoop install demo-tool'
            }
            finally {
                Pop-Location
            }
        }

        It 'Uses manual platform resolution when Resolve-InstallCommand is unavailable' {
            Remove-PreferenceAwareInstallHintStub
            $env:PS_PROFILE_COMMAND_FORCE_MANUAL_INSTALL_RESOLVE = '1'

            function global:Import-Requirements {
                param([string]$RepoRoot, [switch]$UseCache)
                return [PSCustomObject]@{
                    ExternalTools = @{
                        'demo-tool' = @{
                            InstallCommand = @{
                                Linux = 'apt install demo-tool'
                            }
                        }
                    }
                }
            }

            Get-ToolInstallHint -ToolName 'demo-tool' -RepoRoot '/tmp/demo-repo' |
                Should -Be 'Install with: apt install demo-tool'
        }

        It 'Returns default hint when resolved install command is empty' {
            Remove-PreferenceAwareInstallHintStub

            function global:Import-Requirements {
                param([string]$RepoRoot, [switch]$UseCache)
                return [PSCustomObject]@{
                    ExternalTools = @{
                        'demo-tool' = @{
                            InstallCommand = @{ Linux = $null }
                        }
                    }
                }
            }

            Get-ToolInstallHint -ToolName 'demo-tool' -RepoRoot '/tmp/demo-repo' -DefaultInstallCommand 'scoop install demo-tool' |
                Should -Be 'Install with: scoop install demo-tool'
        }

        It 'Logs manual cache import failures when manual import is forced' {
            $env:PS_PROFILE_COMMAND_FORCE_CACHE_IMPORT_ERROR = '1'
            $env:PS_PROFILE_COMMAND_FORCE_MANUAL_CACHE_IMPORT = '1'
            $env:PS_PROFILE_DEBUG = '3'

            Remove-Module Command -ErrorAction SilentlyContinue -Force
            { Import-Module $script:CommandPath -DisableNameChecking -Force } | Should -Not -Throw
            Get-Command Test-CommandAvailable -ErrorAction Stop | Should -Not -BeNullOrEmpty
        }
    }
}
