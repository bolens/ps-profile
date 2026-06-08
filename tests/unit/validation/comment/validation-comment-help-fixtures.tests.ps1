<#
tests/unit/validation-comment-help-fixtures.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-comment-help.ps1 with isolated profile.d fixtures.
#>

function global:New-CommentHelpFixtureRepository {
    param(
        [switch]$IncludeUndocumentedFunction
    )

    $repo = New-TestTempDirectory -Prefix 'CommentHelpFixtureRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    $checksDir = Join-Path $scriptsDir 'checks'
    New-Item -ItemType Directory -Path $checksDir -Force | Out-Null
    Copy-Item -LiteralPath $script:CommentHelpScript -Destination (Join-Path $checksDir 'check-comment-help.ps1') -Force

    $profileDir = Join-Path $repo 'profile.d'
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $profileDir '00-documented.ps1') -Value @'
<#
.SYNOPSIS
    Documented fixture function.
#>
function Test-CommentHelpFixtureOk {
    'ok'
}
'@

    if ($IncludeUndocumentedFunction) {
        Set-Content -LiteralPath (Join-Path $profileDir '99-undocumented.ps1') -Value @'
function Test-CommentHelpFixtureBad { 'bad' }
'@
    }

    New-Item -ItemType Directory -Path (Join-Path $repo '.git') -Force | Out-Null

    return $repo
}

function global:Invoke-CommentHelpCheck {
    param(
        [string]$RepositoryRoot
    )

    $scriptPath = Join-Path $RepositoryRoot 'scripts' 'checks' 'check-comment-help.ps1'
    & pwsh -NoProfile -File $scriptPath 2>&1 | Out-Null
    return $LASTEXITCODE
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
    $script:CommentHelpScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-comment-help.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-comment-help.ps1 fixture execution' {
    It 'Passes when all fixture functions have comment-based help' {
        $repo = New-CommentHelpFixtureRepository
        try {
            Invoke-CommentHelpCheck -RepositoryRoot $repo | Should -Be 0
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when a fixture function is missing comment-based help' {
        $repo = New-CommentHelpFixtureRepository -IncludeUndocumentedFunction
        try {
            Invoke-CommentHelpCheck -RepositoryRoot $repo | Should -BeIn @(1, 2)
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
