<#
tests/unit/test-runner-function-discovery-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FunctionDiscovery scanning behavior.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'FunctionDiscovery.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'FunctionDiscoveryExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FunctionDiscovery extended scenarios' {
    Context 'Get-FunctionsFromPath' {
        It 'Marks functions discovered under profile.d paths' {
            $scanDir = Join-Path $script:TempDir 'profile.d'
            New-Item -ItemType Directory -Path $scanDir -Force | Out-Null

            $file = Join-Path $scanDir '11-git.ps1'
            Set-Content -LiteralPath $file -Value @"
function Get-GitDiscoverySample {
    'ok'
}
"@ -Encoding UTF8

            $functions = @(Get-FunctionsFromPath -Path $scanDir -RepoRoot $script:TestRepoRoot)
            $match = $functions | Where-Object { $_.Name -eq 'Get-GitDiscoverySample' } | Select-Object -First 1

            $match | Should -Not -BeNullOrEmpty
            $match.IsProfileDFile | Should -Be $true
        }

        It 'Does not duplicate functions declared twice in the same file' {
            $scanDir = Join-Path $script:TempDir 'duplicate-scan'
            New-Item -ItemType Directory -Path $scanDir -Force | Out-Null

            $file = Join-Path $scanDir 'duplicate.ps1'
            Set-Content -LiteralPath $file -Value @"
function Get-DuplicateDiscoverySample {
    'declared'
}

Set-AgentModeFunction -Name 'Get-DuplicateDiscoverySample' -Body { 'agent-mode' }
"@ -Encoding UTF8

            $functions = @(Get-FunctionsFromPath -Path $scanDir -RepoRoot $script:TestRepoRoot)
            @($functions | Where-Object { $_.Name -eq 'Get-DuplicateDiscoverySample' }).Count | Should -Be 1
        }

        It 'Flags functions with unapproved verbs' {
            $scanDir = Join-Path $script:TempDir 'verb-scan'
            New-Item -ItemType Directory -Path $scanDir -Force | Out-Null

            $file = Join-Path $scanDir 'invalid-verb.ps1'
            Set-Content -LiteralPath $file -Value @"
function NotApproved-DiscoverySample {
    'bad verb'
}
"@ -Encoding UTF8

            $functions = @(Get-FunctionsFromPath -Path $scanDir -RepoRoot $script:TestRepoRoot)
            $match = $functions | Where-Object { $_.Name -eq 'NotApproved-DiscoverySample' } | Select-Object -First 1

            $match.HasApprovedVerb | Should -Be $false
            $match.IsValidFormat | Should -Be $true
        }

        It 'Computes repository-relative paths for discovered functions' {
            $scanDir = Join-Path $script:TempDir 'relative-scan'
            New-Item -ItemType Directory -Path $scanDir -Force | Out-Null

            $file = Join-Path $scanDir 'relative.ps1'
            Set-Content -LiteralPath $file -Value @"
function Get-RelativeDiscoverySample {
    'relative'
}
"@ -Encoding UTF8

            $functions = @(Get-FunctionsFromPath -Path $scanDir -RepoRoot $script:TestRepoRoot)
            $match = $functions | Where-Object { $_.Name -eq 'Get-RelativeDiscoverySample' } | Select-Object -First 1

            $match.RelativePath | Should -Not -BeNullOrEmpty
            $match.RelativePath | Should -Not -Match [regex]::Escape($script:TestRepoRoot)
            $match.FilePath | Should -Be $file
        }

        It 'Ignores PowerShell files under node_modules directories' {
            $scanDir = Join-Path $script:TempDir 'ignored-scan'
            $ignoredDir = Join-Path $scanDir 'node_modules' 'package'
            New-Item -ItemType Directory -Path $ignoredDir -Force | Out-Null

            $ignoredFile = Join-Path $ignoredDir 'ignored.ps1'
            Set-Content -LiteralPath $ignoredFile -Value @"
function Get-IgnoredDiscoverySample {
    'ignored'
}
"@ -Encoding UTF8

            $functions = @(Get-FunctionsFromPath -Path $scanDir -RepoRoot $script:TestRepoRoot)
            @($functions | Where-Object { $_.Name -eq 'Get-IgnoredDiscoverySample' }).Count | Should -Be 0
        }
    }
}
