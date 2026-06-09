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

    Push-Location $repo
    try {
    git init -q | Out-Null
    git config user.email 'fixture@example.com'
    git config user.name 'Fixture'
    git add profile.d/00-unique.ps1
    if ($IncludeDuplicateDefinition) {
        git add profile.d/01-dup-a.ps1 profile.d/02-dup-b.ps1
    }
    git commit -m 'init duplicate fixture' -q
    }
    finally {
        Pop-Location
    }

    return $repo
}

function global:Invoke-FindDuplicateFunctionsScript {
    param(
        [string]$RepositoryRoot
    )

    $scriptPath = Join-Path $RepositoryRoot 'scripts' 'utils' 'metrics' 'find-duplicate-functions.ps1'
    $output = & pwsh -NoProfile -File $scriptPath 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:DuplicateFunctionsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'metrics' 'find-duplicate-functions.ps1'
    $ConfirmPreference = 'None'
}

Describe 'find-duplicate-functions.ps1 fixture execution' {
    It 'Passes when fixture functions are unique across profile fragments' {
        $repo = New-DuplicateFunctionsFixtureRepository
        $result = Invoke-FindDuplicateFunctionsScript -RepositoryRoot $repo
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'No duplicate function definitions found'
    }

    It 'Fails when the same function name is defined in multiple fragments' {
        $repo = New-DuplicateFunctionsFixtureRepository -IncludeDuplicateDefinition
        $result = Invoke-FindDuplicateFunctionsScript -RepositoryRoot $repo
        $result.ExitCode | Should -BeIn @(1, 2)
        $result.Output | Should -Match 'Test-DuplicateFixtureShared'
        $result.Output | Should -Match 'duplicate function definition'
    }

    It 'Passes when profile.d exists but contains no PowerShell fragment files' {
        $repo = New-TestTempDirectory -Prefix 'DuplicateFunctionsEmptyProfile'
        $scriptsDir = Join-Path $repo 'scripts'
        $metricsDir = Join-Path $scriptsDir 'utils' 'metrics'
        New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force
        Copy-Item -LiteralPath $script:DuplicateFunctionsScript -Destination (Join-Path $metricsDir 'find-duplicate-functions.ps1') -Force
        New-Item -ItemType Directory -Path (Join-Path $repo 'profile.d') -Force | Out-Null
                Push-Location $repo
        try {
            git init -q | Out-Null
            git config user.email 'fixture@example.com'
            git config user.name 'Fixture'
            git commit --allow-empty -m 'init empty profile fixture' -q
        }
        finally {
            Pop-Location
        }
                $result = Invoke-FindDuplicateFunctionsScript -RepositoryRoot $repo
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Scanning 0 file\(s\)|No duplicate function definitions found'
    }

    It 'Reports the number of scanned fragment files in an isolated single-fragment repository' {
        $repo = New-DuplicateFunctionsFixtureRepository
        $result = Invoke-FindDuplicateFunctionsScript -RepositoryRoot $repo
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Scanning 1 file\(s\)'
        $result.Output | Should -Match 'No duplicate function definitions found'
    }
}
