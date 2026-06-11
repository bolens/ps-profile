<#
tests/unit/library-path-resolution-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for profile directory resolution and safe repo root lookup.
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
    Import-Module (Join-Path $script:LibPath 'utilities' 'Cache.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $script:LibPath 'utilities' 'CacheKey.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
    Import-Module (Join-Path $script:LibPath 'path' 'PathResolution.psm1') -DisableNameChecking -Force

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
    $script:TempRoot = New-TestTempDirectory -Prefix 'PathResolutionExtended'
}

AfterAll {
    Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
    Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
    Remove-Module PathResolution -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PathResolution extended scenarios' {
    Context 'Get-ProfileDirectory' {
        It 'Resolves profile.d under the repository root' {
            $profileDir = Get-ProfileDirectory -ScriptPath $PSScriptRoot

            $profileDir | Should -Not -BeNullOrEmpty
            (Split-Path -Leaf $profileDir) | Should -Be 'profile.d'
            Test-Path -LiteralPath $profileDir | Should -Be $true
        }

        It 'Returns the same profile directory on repeated calls' {
            $first = Get-ProfileDirectory -ScriptPath $PSScriptRoot
            $second = Get-ProfileDirectory -ScriptPath $PSScriptRoot

            $second | Should -Be $first
        }
    }

    Context 'Get-RepoRoot and Get-RepoRootSafe' {
        It 'Resolves repository root from unit test file location' {
            $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot

            $repoRoot | Should -Be $script:RepoRoot
            Test-Path -LiteralPath (Join-Path $repoRoot 'profile.d') | Should -Be $true
        }

        It 'Returns null for invalid script paths when ErrorAction is SilentlyContinue' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionOutside'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Throws for invalid script paths by default' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionOutside'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            { Get-RepoRootSafe -ScriptPath $invalidPath } | Should -Throw
        }

        It 'Returns cached repository roots on repeated calls' {
            if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                Clear-CachedValue -Key "RepoRoot_$PSScriptRoot" -ErrorAction SilentlyContinue
            }

            $first = Get-RepoRoot -ScriptPath $PSScriptRoot
            $second = Get-RepoRoot -ScriptPath $PSScriptRoot

            $second | Should -Be $first
        }

        It 'Resolves repository root from a non-existent file under scripts/utils' {
            $candidate = Join-Path $script:RepoRoot 'scripts' 'utils' 'missing-for-coverage.ps1'
            Get-RepoRoot -ScriptPath $candidate | Should -Be $script:RepoRoot
        }

        It 'Resolves repository root using relative script paths from the repo root' {
            Push-Location -LiteralPath $script:RepoRoot
            try {
                Get-RepoRoot -ScriptPath 'scripts/lib/path/PathResolution.psm1' | Should -Be $script:RepoRoot
            }
            finally {
                Pop-Location
            }
        }

        It 'Uses Write-StructuredError for Continue error action when debug is enabled' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionContinue'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction Continue | Should -BeNullOrEmpty
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

        It 'Writes errors when ExitOnError is requested without ExitCodes module' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionExitOnError'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            Remove-Module ExitCodes -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                InModuleScope -ModuleName PathResolution {
                    Mock Get-Command {
                        param($Name)
                        if ($Name -eq 'Exit-WithCode') {
                            return $null
                        }

                        return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                    }

                    { Get-RepoRootSafe -ScriptPath $using:invalidPath -ExitOnError } | Should -Throw
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

    Context 'Get-RepoRoot without Validation helpers' {
        BeforeEach {
            Remove-Module Validation -ErrorAction SilentlyContinue -Force
        }

        AfterEach {
            Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
        }

        It 'Resolves repository root using manual path validation' {
            Get-RepoRoot -ScriptPath $PSScriptRoot | Should -Be $script:RepoRoot
        }

        It 'Constructs absolute paths when the script file does not exist yet' {
            $candidate = Join-Path $script:RepoRoot 'scripts' 'utils' 'future-script.ps1'
            Get-RepoRoot -ScriptPath $candidate | Should -Be $script:RepoRoot
        }
    }

    Context 'Get-RepoRootSafe warning paths' {
        It 'Returns null for invalid paths when ErrorAction is SilentlyContinue' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionSilent'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Emits warning output at debug level 1 without structured logging' {
            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionWarn'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
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

    Context 'Get-RepoRoot repository detection paths' {
        It 'Detects the repository root when walking ancestors from test-artifacts scripts' {
            $fakeRepo = Join-Path $script:TempRoot 'artifact-walk-repo'
            $scriptDir = Join-Path $fakeRepo 'tests' 'test-artifacts' 'scripts' 'nested'
            New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $fakeRepo '.git') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $fakeRepo 'profile.d') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $fakeRepo 'scripts') -Force | Out-Null

            $scriptPath = Join-Path $scriptDir 'runner.ps1'
            Set-Content -LiteralPath $scriptPath -Value '# runner' -Encoding UTF8

            Get-RepoRoot -ScriptPath $scriptPath | Should -Be (Resolve-Path -LiteralPath $fakeRepo).Path
        }

        It 'Detects the repository root from a script directly under scripts' {
            $fakeRepo = Join-Path $script:TempRoot 'scripts-parent-repo'
            $scriptDir = Join-Path $fakeRepo 'scripts' 'checks'
            New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $fakeRepo 'profile.d') -Force | Out-Null

            $scriptPath = Join-Path $scriptDir 'check.ps1'
            Set-Content -LiteralPath $scriptPath -Value '# check' -Encoding UTF8

            Get-RepoRoot -ScriptPath $scriptPath | Should -Be (Resolve-Path -LiteralPath $fakeRepo).Path
        }
    }

    Context 'Get-RepoRoot cache key fallbacks' {
        It 'Uses the fallback cache key format when New-CacheKey is unavailable' {
            $originalCommand = Get-Command New-CacheKey -ErrorAction SilentlyContinue
            Remove-Item -Path Function:New-CacheKey -ErrorAction SilentlyContinue -Force

            try {
                if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                    Clear-CachedValue -Key "RepoRoot_$PSScriptRoot" -ErrorAction SilentlyContinue
                }

                Get-RepoRoot -ScriptPath $PSScriptRoot | Should -Be $script:RepoRoot
            }
            finally {
                Remove-Item -Path Function:New-CacheKey -ErrorAction SilentlyContinue -Force
                if ($originalCommand) {
                    Set-Item -Path Function:\New-CacheKey -Value $originalCommand.ScriptBlock -Force
                }
            }
        }

        It 'Caches profile directory results across repeated calls' {
            if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                Clear-CachedValue -Key "ProfileDirectory_$PSScriptRoot" -ErrorAction SilentlyContinue
            }

            $first = Get-ProfileDirectory -ScriptPath $PSScriptRoot
            $second = Get-ProfileDirectory -ScriptPath $PSScriptRoot

            $second | Should -Be $first
            $first | Should -Be (Join-Path $script:RepoRoot 'profile.d')
        }
    }

    Context 'Get-RepoRootSafe error action branches' {
        It 'Uses manual ErrorAction extraction when Get-ErrorActionPreference is unavailable' {
            Remove-Module ErrorHandling -ErrorAction SilentlyContinue -Force
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionManualPref'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            try {
                Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
            finally {
                Import-Module (Join-Path $script:LibPath 'core' 'ErrorHandling.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Handles non-standard ErrorAction values through the default branch' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionDefaultAction'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction Ignore | Should -BeNullOrEmpty
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

        It 'Uses Write-StructuredError for Continue failures when structured logging is enabled' {
            Enable-TestStructuredLogging
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionStructuredContinue'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                { Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction Continue } | Should -Not -Throw
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

        It 'Uses Write-Error for Continue failures when debug is enabled without structured logging' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionContinueWriteError'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                { Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction Continue } | Should -Not -Throw
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

        It 'Resolves repository root from an existing module file path' {
            $modulePath = Join-Path $script:LibPath 'path' 'PathResolution.psm1'
            $expectedRoot = Get-TestRepoRoot -StartPath $PSScriptRoot

            Get-RepoRoot -ScriptPath $modulePath | Should -Be $expectedRoot
        }

        It 'Uses Write-StructuredError for ExitOnError when debug is enabled' {
            Enable-TestStructuredLogging
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionStructuredExit'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                InModuleScope -ModuleName PathResolution {
                    Mock Get-Command {
                        param($Name)
                        if ($Name -eq 'Exit-WithCode') {
                            return $null
                        }

                        return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                    }

                    { Get-RepoRootSafe -ScriptPath $using:invalidPath -ExitOnError } | Should -Throw
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

        It 'Uses Exit-WithCode when ExitOnError is specified and ExitCodes is available' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionExitWithCode'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            Import-Module (Join-Path $script:LibPath 'core' 'ExitCodes.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue

            try {
                InModuleScope -ModuleName PathResolution -ArgumentList $invalidPath {
                    param([string]$InvalidPath)

                    Mock Exit-WithCode {
                        param($ExitCode, $ErrorRecord)
                        throw "Exit-WithCode invoked with code $ExitCode"
                    }

                    { Get-RepoRootSafe -ScriptPath $InvalidPath -ExitOnError } |
                        Should -Throw '*Exit-WithCode invoked with code*'
                }
            }
            finally {
                Remove-Module ExitCodes -ErrorAction SilentlyContinue -Force
            }
        }

        It 'Logs Continue failures at debug level 1 with structured logging enabled' {
            Enable-TestStructuredLogging
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionContinueDebug1Structured'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction Continue | Should -BeNullOrEmpty
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

        It 'Uses Write-Error for default ErrorAction values when debug is enabled without structured logging' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionDefaultWriteError'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                { Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction Ignore } | Should -Not -Throw
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

        It 'Uses Write-StructuredError for ExitOnError at debug level 1 when Exit-WithCode is unavailable' {
            Enable-TestStructuredLogging
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionExitDebug1Structured'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                InModuleScope -ModuleName PathResolution {
                    Mock Get-Command {
                        param($Name)
                        if ($Name -eq 'Exit-WithCode') {
                            return $null
                        }

                        return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                    }

                    { Get-RepoRootSafe -ScriptPath $using:invalidPath -ExitOnError } | Should -Throw
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

    Context 'Get-RepoRoot path normalization fallbacks' {
        It 'Resolves relative script paths when neither the file nor parent directory exists' {
            $expectedRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            Push-Location -LiteralPath $expectedRoot
            try {
                Get-RepoRoot -ScriptPath 'scripts/utils/nonexistent/future.ps1' | Should -Be $expectedRoot
            }
            finally {
                Pop-Location
            }
        }

        It 'Uses manual validation for absolute paths when the file does not exist' {
            $expectedRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            Remove-Module Validation -ErrorAction SilentlyContinue -Force
            Get-Command Test-ValidPath -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

            try {
                $absoluteMissing = Join-Path $expectedRoot 'scripts' 'utils' 'never-created.ps1'
                Get-RepoRoot -ScriptPath $absoluteMissing | Should -Be $expectedRoot
            }
            finally {
                Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Uses manual validation for relative paths when the file does not exist' {
            $expectedRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            Remove-Module Validation -ErrorAction SilentlyContinue -Force
            Get-Command Test-ValidPath -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

            Push-Location -LiteralPath $expectedRoot
            try {
                Get-RepoRoot -ScriptPath 'scripts/utils/never-created-manual.ps1' | Should -Be $expectedRoot
            }
            finally {
                Pop-Location
                Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Uses manual validation for rooted paths when the file does not exist' {
            $expectedRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            Remove-Module Validation -ErrorAction SilentlyContinue -Force
            Get-Command Test-ValidPath -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

            try {
                $absoluteMissing = Join-Path $expectedRoot 'scripts' 'utils' 'never-created-rooted.ps1'
                Get-RepoRoot -ScriptPath $absoluteMissing | Should -Be $expectedRoot
            }
            finally {
                Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Get-RepoRootSafe additional error branches' {
        It 'Uses Exit-WithCode with fallback exit code when EXIT_SETUP_ERROR is unavailable' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionExitFallbackCode'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            Import-Module (Join-Path $script:LibPath 'core' 'ExitCodes.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
            Remove-Variable -Name EXIT_SETUP_ERROR -Scope Global -ErrorAction SilentlyContinue

            try {
                InModuleScope -ModuleName PathResolution -ArgumentList $invalidPath {
                    param([string]$InvalidPath)

                    Mock Exit-WithCode {
                        param($ExitCode, $ErrorRecord)
                        throw "Exit-WithCode invoked with code $ExitCode"
                    }

                    { Get-RepoRootSafe -ScriptPath $InvalidPath -ExitOnError } |
                        Should -Throw '*Exit-WithCode invoked with code 2*'
                }
            }
            finally {
                Remove-Module ExitCodes -ErrorAction SilentlyContinue -Force
            }
        }

        It 'Uses Write-StructuredError for default ErrorAction values when structured logging is enabled' {
            Enable-TestStructuredLogging
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionDefaultStructured'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction Ignore | Should -BeNullOrEmpty
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

        It 'Uses Write-StructuredError for default ErrorAction values at debug level 1' {
            Enable-TestStructuredLogging
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionDefaultStructuredDebug1'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction Ignore | Should -BeNullOrEmpty
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

        It 'Uses Write-StructuredError for ExitOnError when debug is disabled' {
            Enable-TestStructuredLogging
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionExitStructuredDebugOff'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                InModuleScope -ModuleName PathResolution -ArgumentList $invalidPath {
                    param([string]$InvalidPath)

                    Mock Get-Command {
                        param($Name)
                        if ($Name -eq 'Exit-WithCode') {
                            return $null
                        }

                        return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                    }

                    { Get-RepoRootSafe -ScriptPath $InvalidPath -ExitOnError } | Should -Throw
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

    Context 'PathResolution test environment hooks' {
        It 'Keeps rooted script paths when manual validation cannot resolve parents' {
            $originalFlag = $env:PS_PROFILE_PATH_SKIP_VALIDATION
            $env:PS_PROFILE_PATH_SKIP_VALIDATION = '1'
            $rootedMissing = Join-Path (New-TestExternalTempDirectory -Prefix 'PathResolutionRootedMissing') 'deeply/nested/missing.ps1'

            try {
                { Get-RepoRoot -ScriptPath $rootedMissing } | Should -Throw '*Repository root not found*'
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PATH_SKIP_VALIDATION -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PATH_SKIP_VALIDATION = $originalFlag
                }
            }
        }

        It 'Resolves paths using manual validation when PS_PROFILE_PATH_SKIP_VALIDATION is enabled' {
            $expectedRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            $originalFlag = $env:PS_PROFILE_PATH_SKIP_VALIDATION
            $env:PS_PROFILE_PATH_SKIP_VALIDATION = '1'

            Push-Location -LiteralPath $expectedRoot
            try {
                Get-RepoRoot -ScriptPath 'scripts/utils/manual-env-hook.ps1' | Should -Be $expectedRoot
            }
            finally {
                Pop-Location
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PATH_SKIP_VALIDATION -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PATH_SKIP_VALIDATION = $originalFlag
                }
            }
        }

        It 'Loads module dependencies through manual import fallbacks when forced' {
            $originalFlag = $env:PS_PROFILE_PATH_FORCE_MANUAL_IMPORT
            $env:PS_PROFILE_PATH_FORCE_MANUAL_IMPORT = '1'

            Get-Module PathResolution, Cache, ErrorHandling, SafeImport -All |
                Remove-Module -Force -ErrorAction SilentlyContinue

            try {
                Import-Module (Join-Path $script:LibPath 'path' 'PathResolution.psm1') -DisableNameChecking -Force
                Get-Command Get-RepoRoot -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Module PathResolution -ErrorAction SilentlyContinue -Force
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PATH_FORCE_MANUAL_IMPORT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PATH_FORCE_MANUAL_IMPORT = $originalFlag
                }

                Import-Module (Join-Path $script:LibPath 'utilities' 'Cache.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
                Import-Module (Join-Path $script:LibPath 'core' 'ErrorHandling.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
                Import-Module (Join-Path $script:LibPath 'path' 'PathResolution.psm1') -DisableNameChecking -Force
            }
        }

        It 'Uses Write-Error for Continue failures when structured logging is disabled via env flag' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionEnvContinue'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            $originalStructuredFlag = $env:PS_PROFILE_PATH_DISABLE_STRUCTURED_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PATH_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '0'

            try {
                Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction Continue | Should -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_PATH_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PATH_DISABLE_STRUCTURED_ERROR = $originalStructuredFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses Write-Error for ExitOnError when structured logging is disabled via env flag' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionEnvExit'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            $originalStructuredFlag = $env:PS_PROFILE_PATH_DISABLE_STRUCTURED_ERROR
            $originalExitWithCodeFlag = $env:PS_PROFILE_PATH_DISABLE_EXIT_WITH_CODE
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_PATH_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_PATH_DISABLE_EXIT_WITH_CODE = '1'
            $env:PS_PROFILE_DEBUG = '0'

            try {
                Get-RepoRootSafe -ScriptPath $invalidPath -ExitOnError -ErrorAction SilentlyContinue |
                    Should -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_PATH_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PATH_DISABLE_STRUCTURED_ERROR = $originalStructuredFlag
                }

                if ($null -eq $originalExitWithCodeFlag) {
                    Remove-Item Env:PS_PROFILE_PATH_DISABLE_EXIT_WITH_CODE -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PATH_DISABLE_EXIT_WITH_CODE = $originalExitWithCodeFlag
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

    Context 'Get-RepoRoot isolated without Validation' {
        It 'Resolves paths using manual validation when Validation was never loaded' {
            $expectedRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            $isolatedDir = Join-Path $script:TempRoot 'path-no-validation'
            $isolatedCore = Join-Path (Split-Path -Parent $isolatedDir) 'core'
            New-Item -ItemType Directory -Path $isolatedDir, $isolatedCore -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:LibPath 'path' 'PathResolution.psm1') -Destination $isolatedDir
            Copy-Item -LiteralPath (Join-Path $script:LibPath 'utilities' 'Cache.psm1') -Destination $isolatedDir
            Copy-Item -LiteralPath (Join-Path $script:LibPath 'core' 'ErrorHandling.psm1') -Destination $isolatedCore

            Get-Module SafeImport, PathResolution, Cache, ErrorHandling, Validation -All |
                Remove-Module -Force -ErrorAction SilentlyContinue
            Remove-Item -Path Function:\Test-ValidPath -ErrorAction SilentlyContinue -Force

            try {
                Import-Module (Join-Path $isolatedDir 'PathResolution.psm1') -DisableNameChecking -Force
                Get-Command Test-ValidPath -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

                Push-Location -LiteralPath $expectedRoot
                try {
                    Get-RepoRoot -ScriptPath 'scripts/utils/future-manual-isolated.ps1' | Should -Be $expectedRoot
                }
                finally {
                    Pop-Location
                }

                $absoluteMissing = Join-Path $expectedRoot 'scripts' 'utils' 'future-manual-isolated-abs.ps1'
                Get-RepoRoot -ScriptPath $absoluteMissing | Should -Be $expectedRoot
            }
            finally {
                Remove-Module PathResolution -ErrorAction SilentlyContinue -Force
                Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
                Import-Module (Join-Path $script:LibPath 'utilities' 'Cache.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
                Import-Module (Join-Path $script:LibPath 'core' 'ErrorHandling.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
                Import-Module (Join-Path $script:LibPath 'path' 'PathResolution.psm1') -DisableNameChecking -Force
            }
        }
    }

    Context 'Get-RepoRootSafe Write-Error fallback branches' {
        It 'Uses Write-Error for Continue failures when structured logging is unavailable' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionContinueWriteErrorOff'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction Continue | Should -BeNullOrEmpty
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

        It 'Uses Write-Error for default ErrorAction values when structured logging is unavailable' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionDefaultWriteErrorOff'
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null

            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '0'

            try {
                Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction Ignore | Should -BeNullOrEmpty
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

    Context 'Get-ProfileDirectory cache key fallbacks' {
        It 'Uses the fallback cache key format when New-CacheKey is unavailable' {
            $originalCommand = Get-Command New-CacheKey -ErrorAction SilentlyContinue
            Remove-Item -Path Function:New-CacheKey -ErrorAction SilentlyContinue -Force

            try {
                if (Get-Command Clear-CachedValue -ErrorAction SilentlyContinue) {
                    Clear-CachedValue -Key "ProfileDirectory_$PSScriptRoot" -ErrorAction SilentlyContinue
                }

                $profileDir = Get-ProfileDirectory -ScriptPath $PSScriptRoot
                $profileDir | Should -Not -BeNullOrEmpty
                (Split-Path -Leaf $profileDir) | Should -Be 'profile.d'
                $profileDir | Should -Be (Join-Path (Get-RepoRoot -ScriptPath $PSScriptRoot) 'profile.d')
            }
            finally {
                Remove-Item -Path Function:New-CacheKey -ErrorAction SilentlyContinue -Force
                if ($originalCommand) {
                    Set-Item -Path Function:\New-CacheKey -Value $originalCommand.ScriptBlock -Force
                }
            }
        }
    }

    Context 'Get-RepoRoot scripts directory detection' {
        It 'Skips scripts directories that are not repository roots' {
            $outsideRoot = New-TestExternalTempDirectory -Prefix 'PathResolutionNonRepoScripts'
            $scriptDir = Join-Path $outsideRoot 'scripts' 'nested'
            New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null

            $scriptPath = Join-Path $scriptDir 'runner.ps1'
            Set-Content -LiteralPath $scriptPath -Value '# runner' -Encoding UTF8

            { Get-RepoRoot -ScriptPath $scriptPath } | Should -Throw '*Repository root not found*'
        }
    }

    Context 'PathResolution module initialization' {
        It 'Loads through manual import fallbacks when SafeImport is unavailable' {
            $isolatedDir = Join-Path $script:TempRoot 'path-isolated'
            $isolatedCore = Join-Path (Split-Path -Parent $isolatedDir) 'core'
            New-Item -ItemType Directory -Path $isolatedDir -Force | Out-Null
            New-Item -ItemType Directory -Path $isolatedCore -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:LibPath 'path' 'PathResolution.psm1') -Destination $isolatedDir
            Copy-Item -LiteralPath (Join-Path $script:LibPath 'utilities' 'Cache.psm1') -Destination $isolatedDir
            Copy-Item -LiteralPath (Join-Path $script:LibPath 'core' 'ErrorHandling.psm1') -Destination $isolatedCore

            Get-Module SafeImport, PathResolution, Cache, ErrorHandling -All |
                Remove-Module -Force -ErrorAction SilentlyContinue
            Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

            try {
                { Import-Module (Join-Path $isolatedDir 'PathResolution.psm1') -DisableNameChecking -Force } | Should -Not -Throw
                Get-Command Get-RepoRoot -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Module PathResolution -ErrorAction SilentlyContinue -Force
                Import-Module (Join-Path $script:LibPath 'utilities' 'Cache.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
                Import-Module (Join-Path $script:LibPath 'core' 'ErrorHandling.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
                Import-Module (Join-Path $script:LibPath 'path' 'PathResolution.psm1') -DisableNameChecking -Force
            }
        }
    }
}
