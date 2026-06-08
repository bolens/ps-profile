<#
tests/unit/library-path-resolution-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for profile directory resolution and safe repo root lookup.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'path' 'PathResolution.psm1') -DisableNameChecking -Force

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempRoot = New-TestTempDirectory -Prefix 'PathResolutionExtended'
}

AfterAll {
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
            # Outside the repository: system temp is required; register for AfterEach cleanup.
            $outsideRoot = Join-Path ([System.IO.Path]::GetTempPath()) "PathResolutionOutside-$(Get-Random)"
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null
            Register-TestCleanupPath -Path $outsideRoot

            Get-RepoRootSafe -ScriptPath $invalidPath -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Throws for invalid script paths by default' {
            $outsideRoot = Join-Path ([System.IO.Path]::GetTempPath()) "PathResolutionOutside-$(Get-Random)"
            $invalidPath = Join-Path $outsideRoot 'scripts/missing.ps1'
            New-Item -ItemType Directory -Path (Split-Path $invalidPath) -Force | Out-Null
            Register-TestCleanupPath -Path $outsideRoot

            { Get-RepoRootSafe -ScriptPath $invalidPath } | Should -Throw
        }
    }
}
