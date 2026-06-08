<#
tests/unit/library-profile-scoop.tests.ps1

.SYNOPSIS
    Unit tests for ProfileScoop module.
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
    $script:TempDir = New-TestTempDirectory -Prefix 'ProfileScoopTests'
    $script:OriginalScoop = $env:SCOOP
    $script:OriginalScoopGlobal = $env:SCOOP_GLOBAL
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

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ProfileScoop Module' {
    Context 'Initialize-ProfileScoop' {
        BeforeEach {
            Clear-TestStartProcessCapture
            Remove-Item Env:\SCOOP -ErrorAction SilentlyContinue
            Remove-Item Env:\SCOOP_GLOBAL -ErrorAction SilentlyContinue
        }

        AfterEach {
            Get-TestStartProcessCapture | Should -BeNullOrEmpty
        }

        It 'Does not throw when ScoopDetection module is missing' {
            { Initialize-ProfileScoop -ProfileDir $script:TempDir } | Should -Not -Throw
        }

        It 'Adds legacy Scoop shims to PATH when SCOOP is set' {
            $scoopRoot = New-TestTempDirectory -Prefix 'ProfileScoopRoot'
            $shimsDir = Join-Path $scoopRoot 'shims'
            New-Item -ItemType Directory -Path $shimsDir -Force | Out-Null
            $env:SCOOP = $scoopRoot

            Initialize-ProfileScoop -ProfileDir $script:TempDir

            $env:PATH | Should -Match ([regex]::Escape($shimsDir))
        }

        It 'Uses repository ScoopDetection when available' {
            $detectionModule = Join-Path $script:RepoRoot 'scripts/lib/runtime/ScoopDetection.psm1'
            if (-not (Test-Path -LiteralPath $detectionModule)) {
                Set-ItResult -Inconclusive -Because 'ScoopDetection module is unavailable in this workspace'
                return
            }

            { Initialize-ProfileScoop -ProfileDir $script:RepoRoot } | Should -Not -Throw
        }
    }

    Context 'Initialize-ProfileScoopLegacy' {
        BeforeEach {
            Clear-TestStartProcessCapture
            Remove-Item Env:\SCOOP -ErrorAction SilentlyContinue
            Remove-Item Env:\SCOOP_GLOBAL -ErrorAction SilentlyContinue
        }

        AfterEach {
            Get-TestStartProcessCapture | Should -BeNullOrEmpty
        }

        It 'Does not throw when no Scoop installation is detected' {
            { Initialize-ProfileScoopLegacy } | Should -Not -Throw
        }
    }
}
