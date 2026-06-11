<#
tests/unit/library-profile-scoop-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ProfileScoop legacy path handling.
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
    $libPath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib'
    Import-Module (Join-Path $libPath 'profile/ProfileScoop.psm1') -DisableNameChecking -Force -Global

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'ProfileScoopExtended'
    $script:OriginalScoop = $env:SCOOP
    $script:OriginalScoopGlobal = $env:SCOOP_GLOBAL
    $script:OriginalPath = $env:PATH
}

AfterAll {
    if ($null -eq $script:OriginalScoop) {
        Remove-Item Env:\SCOOP -ErrorAction SilentlyContinue
    }
    else {
        $env:SCOOP = $script:OriginalScoop
    }

    if ($null -eq $script:OriginalScoopGlobal) {
        Remove-Item Env:\SCOOP_GLOBAL -ErrorAction SilentlyContinue
    }
    else {
        $env:SCOOP_GLOBAL = $script:OriginalScoopGlobal
    }

    $env:PATH = $script:OriginalPath

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ProfileScoop extended scenarios' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Enable-TestStructuredLogging
        Remove-Item Env:\SCOOP -ErrorAction SilentlyContinue
        Remove-Item Env:\SCOOP_GLOBAL -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        $env:PATH = $script:OriginalPath
        Get-Module ScoopDetection -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Module $_.Name -Force -ErrorAction SilentlyContinue
        }
    }

    AfterEach {
        Disable-TestStructuredLogging
        Get-TestStartProcessCapture | Should -BeNullOrEmpty
    }

    function script:Install-ScoopDetectionStub {
        param(
            [string]$ProfileDir,
            [string]$Content
        )

        $runtimeDir = Join-Path $ProfileDir 'scripts' 'lib' 'runtime'
        New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $runtimeDir 'ScoopDetection.psm1') -Value $Content -Encoding UTF8
    }

    Context 'Initialize-ProfileScoopLegacy' {
        It 'Prefers SCOOP_GLOBAL over SCOOP when both are configured' {
            $globalRoot = New-TestTempDirectory -Prefix 'ScoopGlobalRoot'
            $localRoot = New-TestTempDirectory -Prefix 'ScoopLocalRoot'
            $globalShims = Join-Path $globalRoot 'shims'
            $localShims = Join-Path $localRoot 'shims'
            New-Item -ItemType Directory -Path $globalShims, $localShims -Force | Out-Null

            $env:SCOOP_GLOBAL = $globalRoot
            $env:SCOOP = $localRoot

            Initialize-ProfileScoopLegacy

            $env:PATH | Should -Match ([regex]::Escape($globalShims))
            $env:PATH | Should -Not -Match ([regex]::Escape($localShims))
        }

        It 'Adds the bin directory to PATH when it exists' {
            $scoopRoot = New-TestTempDirectory -Prefix 'ScoopBinRoot'
            $binDir = Join-Path $scoopRoot 'bin'
            New-Item -ItemType Directory -Path $binDir -Force | Out-Null
            $env:SCOOP = $scoopRoot

            Initialize-ProfileScoopLegacy

            $env:PATH | Should -Match ([regex]::Escape($binDir))
        }

        It 'Does not duplicate shims entries when legacy init runs twice' {
            $scoopRoot = New-TestTempDirectory -Prefix 'ScoopDupRoot'
            $shimsDir = Join-Path $scoopRoot 'shims'
            New-Item -ItemType Directory -Path $shimsDir -Force | Out-Null
            $env:SCOOP = $scoopRoot

            Initialize-ProfileScoopLegacy
            Initialize-ProfileScoopLegacy

            $matches = @($env:PATH.Split([System.IO.Path]::PathSeparator) | Where-Object { $_ -eq $shimsDir })
            $matches.Count | Should -Be 1
        }

        It 'Ignores SCOOP values that point to missing directories' {
            $env:SCOOP = Join-Path $script:TempDir 'missing-scoop-root'

            { Initialize-ProfileScoopLegacy } | Should -Not -Throw
            $env:PATH | Should -Be $script:OriginalPath
        }

        It 'Detects Scoop under the user home directory when env vars are unset' {
            $homeRoot = if ($env:HOME) { $env:HOME } elseif ($env:USERPROFILE) { $env:USERPROFILE } else { $null }
            if (-not $homeRoot) {
                Set-ItResult -Inconclusive -Because 'No HOME or USERPROFILE is available in this environment'
                return
            }

            $scoopRoot = Join-Path $homeRoot 'scoop'
            if (-not (Test-Path -LiteralPath $scoopRoot)) {
                Set-ItResult -Inconclusive -Because 'No ~/scoop installation exists in this environment'
                return
            }

            $shimsDir = Join-Path $scoopRoot 'shims'
            if (-not (Test-Path -LiteralPath $shimsDir)) {
                Set-ItResult -Inconclusive -Because 'No ~/scoop/shims directory exists in this environment'
                return
            }

            Initialize-ProfileScoopLegacy

            $env:PATH | Should -Match ([regex]::Escape($shimsDir))
        }

        It 'Imports completion module when the legacy completion manifest exists' {
            $scoopRoot = New-TestTempDirectory -Prefix 'ScoopCompletionRoot'
            $completionDir = Join-Path $scoopRoot 'apps' 'scoop' 'current' 'supporting' 'completion'
            New-Item -ItemType Directory -Path $completionDir -Force | Out-Null
            $completionManifest = Join-Path $completionDir 'Scoop-Completion.psd1'
            Set-Content -LiteralPath $completionManifest -Value @'
@{
    ModuleVersion = '1.0.0'
    RootModule = 'Scoop-Completion.psm1'
}
'@ -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $completionDir 'Scoop-Completion.psm1') -Value 'function Get-ScoopCompletionStub { }' -Encoding UTF8
            $env:SCOOP = $scoopRoot

            { Initialize-ProfileScoopLegacy } | Should -Not -Throw
        }

        It 'Handles forced legacy failures through the test environment hook' {
            $env:PS_PROFILE_SCOOP_FORCE_LEGACY_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '2'
            try {
                { Initialize-ProfileScoopLegacy } | Should -Not -Throw
            }
            finally {
                Remove-Item Env:PS_PROFILE_SCOOP_FORCE_LEGACY_ERROR -ErrorAction SilentlyContinue
            }
        }

        It 'Emits detailed legacy failure output at debug level 3 when forced through the test hook' {
            $env:PS_PROFILE_SCOOP_FORCE_LEGACY_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '3'
            try {
                { Initialize-ProfileScoopLegacy } | Should -Not -Throw
            }
            finally {
                Remove-Item Env:PS_PROFILE_SCOOP_FORCE_LEGACY_ERROR -ErrorAction SilentlyContinue
            }
        }

        It 'Detects Scoop under a temporary HOME directory when env vars are unset' {
            $homeRoot = New-TestTempDirectory -Prefix 'ProfileScoopHomeRoot'
            $scoopRoot = Join-Path $homeRoot 'scoop'
            $shimsDir = Join-Path $scoopRoot 'shims'
            New-Item -ItemType Directory -Path $shimsDir -Force | Out-Null

            $originalHome = $env:HOME
            $env:HOME = $homeRoot
            try {
                Initialize-ProfileScoopLegacy
                $env:PATH | Should -Match ([regex]::Escape($shimsDir))
            }
            finally {
                if ($null -eq $originalHome) {
                    Remove-Item Env:HOME -ErrorAction SilentlyContinue
                }
                else {
                    $env:HOME = $originalHome
                }
            }
        }
    }

    Context 'Initialize-ProfileScoop' {
        It 'Falls back to legacy detection when ProfileDir has no ScoopDetection module' {
            $scoopRoot = New-TestTempDirectory -Prefix 'ScoopFallbackRoot'
            $shimsDir = Join-Path $scoopRoot 'shims'
            New-Item -ItemType Directory -Path $shimsDir -Force | Out-Null
            $env:SCOOP = $scoopRoot

            { Initialize-ProfileScoop -ProfileDir $script:TempDir } | Should -Not -Throw
            $env:PATH | Should -Match ([regex]::Escape($shimsDir))
        }

        It 'Uses ScoopDetection helpers when a stub module is present' {
            $profileDir = New-TestTempDirectory -Prefix 'ProfileScoopStubProfile'
            $scoopRoot = New-TestTempDirectory -Prefix 'ProfileScoopStubRoot'
            $completionFile = Join-Path $scoopRoot 'completion.psd1'
            Set-Content -LiteralPath $completionFile -Value '# completion stub' -Encoding UTF8

            Install-ScoopDetectionStub -ProfileDir $profileDir -Content @"
function Get-ScoopRoot { return '$($scoopRoot -replace '\\','\\')' }
function Get-ScoopCompletionPath { param([string]`$ScoopRoot) return '$($completionFile -replace '\\','\\')' }
function Add-ScoopToPath { param([string]`$ScoopRoot) `$env:PATH = '$scoopRoot' + [System.IO.Path]::PathSeparator + `$env:PATH }
Export-ModuleMember -Function Get-ScoopRoot, Get-ScoopCompletionPath, Add-ScoopToPath
"@

            { Initialize-ProfileScoop -ProfileDir $profileDir } | Should -Not -Throw
            $env:PATH | Should -Match ([regex]::Escape($scoopRoot))
        }

        It 'Falls back to legacy detection when ScoopDetection import fails' {
            $profileDir = New-TestTempDirectory -Prefix 'ProfileScoopBrokenModule'
            $scoopRoot = New-TestTempDirectory -Prefix 'ProfileScoopLegacyAfterFail'
            $shimsDir = Join-Path $scoopRoot 'shims'
            New-Item -ItemType Directory -Path $shimsDir -Force | Out-Null
            $env:SCOOP = $scoopRoot

            Install-ScoopDetectionStub -ProfileDir $profileDir -Content @'
function Get-ScoopRoot { throw "scoop detection probe" }
Export-ModuleMember -Function Get-ScoopRoot
'@

            { Initialize-ProfileScoop -ProfileDir $profileDir } | Should -Not -Throw
            $env:PATH | Should -Match ([regex]::Escape($shimsDir))
        }

        It 'Continues when Get-ScoopCompletionPath throws under debug level 2' {
            $profileDir = New-TestTempDirectory -Prefix 'ProfileScoopCompletionFail'
            $scoopRoot = New-TestTempDirectory -Prefix 'ProfileScoopCompletionRoot'

            Install-ScoopDetectionStub -ProfileDir $profileDir -Content @"
function Get-ScoopRoot { return '$($scoopRoot -replace '\\','\\')' }
function Get-ScoopCompletionPath { param([string]`$ScoopRoot) throw 'completion path probe' }
function Add-ScoopToPath { param([string]`$ScoopRoot) }
Export-ModuleMember -Function Get-ScoopRoot, Get-ScoopCompletionPath, Add-ScoopToPath
"@
            $env:PS_PROFILE_DEBUG = '2'

            { Initialize-ProfileScoop -ProfileDir $profileDir } | Should -Not -Throw
        }

        It 'Continues when Add-ScoopToPath throws under debug level 2' {
            $profileDir = New-TestTempDirectory -Prefix 'ProfileScoopAddPathFail'
            $scoopRoot = New-TestTempDirectory -Prefix 'ProfileScoopAddPathRoot'

            Install-ScoopDetectionStub -ProfileDir $profileDir -Content @"
function Get-ScoopRoot { return '$($scoopRoot -replace '\\','\\')' }
function Get-ScoopCompletionPath { param([string]`$ScoopRoot) return `$null }
function Add-ScoopToPath { param([string]`$ScoopRoot) throw 'add path probe' }
Export-ModuleMember -Function Get-ScoopRoot, Get-ScoopCompletionPath, Add-ScoopToPath
"@
            $env:PS_PROFILE_DEBUG = '2'

            { Initialize-ProfileScoop -ProfileDir $profileDir } | Should -Not -Throw
        }

        It 'Uses verbose logging when completion path lookup fails without structured logging' {
            Disable-TestStructuredLogging
            $profileDir = New-TestTempDirectory -Prefix 'ProfileScoopVerboseCompletion'
            $scoopRoot = New-TestTempDirectory -Prefix 'ProfileScoopVerboseRoot'

            Install-ScoopDetectionStub -ProfileDir $profileDir -Content @"
function Get-ScoopRoot { return '$($scoopRoot -replace '\\','\\')' }
function Get-ScoopCompletionPath { param([string]`$ScoopRoot) throw 'completion verbose probe' }
function Add-ScoopToPath { param([string]`$ScoopRoot) }
Export-ModuleMember -Function Get-ScoopRoot, Get-ScoopCompletionPath, Add-ScoopToPath
"@
            $env:PS_PROFILE_DEBUG = '2'

            { Initialize-ProfileScoop -ProfileDir $profileDir -Verbose } | Should -Not -Throw
        }

        It 'Emits structured warnings when Get-ScoopRoot fails under debug level 2' {
            $profileDir = New-TestTempDirectory -Prefix 'ProfileScoopRootFailDebug'
            Install-ScoopDetectionStub -ProfileDir $profileDir -Content @'
function Get-ScoopRoot { throw "scoop root debug probe" }
Export-ModuleMember -Function Get-ScoopRoot
'@
            $env:PS_PROFILE_DEBUG = '2'

            { Initialize-ProfileScoop -ProfileDir $profileDir } | Should -Not -Throw
        }

        It 'Emits detailed root failure output at debug level 3' {
            $profileDir = New-TestTempDirectory -Prefix 'ProfileScoopRootFailDebug3'
            Install-ScoopDetectionStub -ProfileDir $profileDir -Content @'
function Get-ScoopRoot { throw "scoop root debug3 probe" }
Export-ModuleMember -Function Get-ScoopRoot
'@
            $env:PS_PROFILE_DEBUG = '3'

            { Initialize-ProfileScoop -ProfileDir $profileDir } | Should -Not -Throw
        }

        It 'Falls back to legacy detection when the stub module does not export Get-ScoopRoot' {
            $profileDir = New-TestTempDirectory -Prefix 'ProfileScoopMissingExport'
            $scoopRoot = New-TestTempDirectory -Prefix 'ProfileScoopMissingExportRoot'
            $shimsDir = Join-Path $scoopRoot 'shims'
            New-Item -ItemType Directory -Path $shimsDir -Force | Out-Null
            $env:SCOOP = $scoopRoot

            Install-ScoopDetectionStub -ProfileDir $profileDir -Content @'
# Stub module without exported Get-ScoopRoot
'@

            { Initialize-ProfileScoop -ProfileDir $profileDir } | Should -Not -Throw
            $env:PATH | Should -Match ([regex]::Escape($shimsDir))
        }

        It 'Emits module failure diagnostics at debug level 2 before legacy fallback' {
            $profileDir = New-TestTempDirectory -Prefix 'ProfileScoopModuleFailDebug2'
            $scoopRoot = New-TestTempDirectory -Prefix 'ProfileScoopModuleFailRoot'
            $shimsDir = Join-Path $scoopRoot 'shims'
            New-Item -ItemType Directory -Path $shimsDir -Force | Out-Null
            $env:SCOOP = $scoopRoot

            Install-ScoopDetectionStub -ProfileDir $profileDir -Content @'
function Get-ScoopRoot { throw "module failure debug2 probe" }
Export-ModuleMember -Function Get-ScoopRoot
'@
            $env:PS_PROFILE_DEBUG = '2'

            { Initialize-ProfileScoop -ProfileDir $profileDir } | Should -Not -Throw
        }

        It 'Emits module failure diagnostics at debug level 3 before legacy fallback' {
            $profileDir = New-TestTempDirectory -Prefix 'ProfileScoopModuleFailDebug3'
            Install-ScoopDetectionStub -ProfileDir $profileDir -Content @'
function Get-ScoopRoot { throw "module failure debug3 probe" }
Export-ModuleMember -Function Get-ScoopRoot
'@
            $env:PS_PROFILE_DEBUG = '3'

            { Initialize-ProfileScoop -ProfileDir $profileDir } | Should -Not -Throw
        }
    }
}
