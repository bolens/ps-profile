<#
tests/unit/validation-comment-help.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-comment-help.ps1 with isolated profile.d fixtures.
#>

function global:New-CommentHelpTestRepository {
    param(
        [switch]$IncludeUndocumentedFunction
    )

    $repo = New-TestTempDirectory -Prefix 'CommentHelpRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    $checksDir = Join-Path $scriptsDir 'checks'
    New-Item -ItemType Directory -Path $checksDir -Force | Out-Null
    Copy-Item -LiteralPath $script:CommentHelpScript -Destination (Join-Path $checksDir 'check-comment-help.ps1') -Force

    $profileDir = Join-Path $repo 'profile.d'
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null

    if ($IncludeUndocumentedFunction) {
        Set-Content -LiteralPath (Join-Path $profileDir '00-missing-help.ps1') -Value @'
function Get-CommentHelpMissingFixture {
    'missing help'
}
'@ -Encoding UTF8
    }
    else {
        Set-Content -LiteralPath (Join-Path $profileDir '00-documented.ps1') -Value @'
<#
.SYNOPSIS
    Fixture function with comment-based help.
.DESCRIPTION
    Used by comment-help validation tests.
#>
function Get-CommentHelpDocumentedFixture {
    'ok'
}
'@ -Encoding UTF8
    }

    Push-Location $repo
    try {
        git init -q | Out-Null
        git config user.email 'fixture@example.com'
        git config user.name 'Fixture'
        git add profile.d/
        git commit -m 'init comment-help fixture' -q
    }
    finally {
        Pop-Location
    }

    return $repo
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
    $script:GitAvailable = [bool](Get-Command git -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'check-comment-help.ps1' {
    It 'Passes when every function in profile.d has comment-based help' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }

        $repo = New-CommentHelpTestRepository
        try {
            Push-Location $repo
            try {
                $result = Invoke-TestScriptFile -ScriptPath (Join-Path $repo 'scripts' 'checks' 'check-comment-help.ps1')
            }
            finally {
                Pop-Location
            }

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'All functions have comment-based help'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when profile.d contains functions without comment-based help' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }

        $repo = New-CommentHelpTestRepository -IncludeUndocumentedFunction
        try {
            Push-Location $repo
            try {
                $result = Invoke-TestScriptFile -ScriptPath (Join-Path $repo 'scripts' 'checks' 'check-comment-help.ps1')
            }
            finally {
                Pop-Location
            }

            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'MISSING HELP|missing comment-based help|Get-CommentHelpMissingFixture'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
