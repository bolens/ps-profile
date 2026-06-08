<#
tests/unit/utility-find-duplicate-functions.tests.ps1

.SYNOPSIS
    Behavioral unit tests for find-duplicate-functions.ps1 with isolated profile.d fixtures.
#>

function global:New-DuplicateFunctionsFixtureRepository {
    param(
        [switch]$IncludeDuplicateDefinition
    )

    $repo = New-TestTempDirectory -Prefix 'DuplicateFunctionsRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    $metricsDir = Join-Path $scriptsDir 'utils' 'metrics'
    New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
    Copy-Item -LiteralPath $script:DuplicateFunctionsScript -Destination (Join-Path $metricsDir 'find-duplicate-functions.ps1') -Force

    $profileDir = Join-Path $repo 'profile.d'
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $profileDir '00-unique.ps1') -Value @'
function Test-DuplicateFixtureUnique { 'one' }
'@

    if ($IncludeDuplicateDefinition) {
        Set-Content -LiteralPath (Join-Path $profileDir '01-dup-a.ps1') -Value @'
function Test-DuplicateFixtureShared { 'a' }
'@
        Set-Content -LiteralPath (Join-Path $profileDir '02-dup-b.ps1') -Value @'
function Test-DuplicateFixtureShared { 'b' }
'@
    }

    New-Item -ItemType Directory -Path (Join-Path $repo '.git') -Force | Out-Null

    return $repo
}

function global:Invoke-FindDuplicateFunctionsScript {
    param(
        [string]$RepositoryRoot
    )

    $scriptPath = Join-Path $RepositoryRoot 'scripts' 'utils' 'metrics' 'find-duplicate-functions.ps1'
    & pwsh -NoProfile -File $scriptPath 2>&1 | Out-Null
    return $LASTEXITCODE
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:DuplicateFunctionsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'metrics' 'find-duplicate-functions.ps1'
    $ConfirmPreference = 'None'
}

Describe 'find-duplicate-functions.ps1 fixture execution' {
    It 'Passes when fixture functions are unique across profile fragments' {
        $repo = New-DuplicateFunctionsFixtureRepository
        try {
            Invoke-FindDuplicateFunctionsScript -RepositoryRoot $repo | Should -Be 0
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when the same function name is defined in multiple fragments' {
        $repo = New-DuplicateFunctionsFixtureRepository -IncludeDuplicateDefinition
        try {
            Invoke-FindDuplicateFunctionsScript -RepositoryRoot $repo | Should -BeIn @(1, 2)
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
