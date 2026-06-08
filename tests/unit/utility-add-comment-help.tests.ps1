<#
tests/unit/utility-add-comment-help.tests.ps1

.SYNOPSIS
    Behavioral unit tests for add-comment-help.ps1 DryRun on isolated fixtures.
#>

function global:New-CommentHelpFixtureDirectory {
    $fixtureDir = New-TestTempDirectory -Prefix 'CommentHelpFixture'
    Set-Content -LiteralPath (Join-Path $fixtureDir 'needs-help.ps1') -Value @'
function Get-CommentHelpFixtureOk {
    'ok'
}
'@ -Encoding UTF8
    return $fixtureDir
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:AddCommentHelpScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'add-comment-help.ps1'
    $ConfirmPreference = 'None'
}

Describe 'add-comment-help.ps1 execution' {
    It 'DryRun previews help additions without modifying fixture files' {
        $fixtureDir = New-CommentHelpFixtureDirectory
        try {
            $fixtureFile = Join-Path $fixtureDir 'needs-help.ps1'
            $before = Get-Content -LiteralPath $fixtureFile -Raw

            $result = Invoke-TestScriptFile -ScriptPath $script:AddCommentHelpScript -ArgumentList @(
                '-Path', $fixtureDir,
                '-DryRun'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'DryRun|would add|Get-CommentHelpFixtureOk'
            (Get-Content -LiteralPath $fixtureFile -Raw) | Should -Be $before
        }
        finally {
            if (Test-Path -LiteralPath $fixtureDir) {
                Remove-Item -LiteralPath $fixtureDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
