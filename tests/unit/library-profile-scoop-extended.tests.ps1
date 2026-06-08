<#
tests/unit/library-profile-scoop-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ProfileScoop legacy path handling.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Join-Path $PSScriptRoot '../../scripts/lib'
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
        Remove-Item Env:\SCOOP -ErrorAction SilentlyContinue
        Remove-Item Env:\SCOOP_GLOBAL -ErrorAction SilentlyContinue
        $env:PATH = $script:OriginalPath
    }

    AfterEach {
        Get-TestStartProcessCapture | Should -BeNullOrEmpty
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
    }
}
