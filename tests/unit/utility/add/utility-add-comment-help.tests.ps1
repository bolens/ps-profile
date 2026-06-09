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
    $script:AddCommentHelpScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'add-comment-help.ps1'
    $ConfirmPreference = 'None'
}

Describe 'add-comment-help.ps1 execution' {
    It 'DryRun previews help additions without modifying fixture files' {
        $fixtureDir = New-CommentHelpFixtureDirectory
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

    It 'Adds comment-based help to fixture functions when not in DryRun mode' {
        $fixtureDir = New-CommentHelpFixtureDirectory
            $fixtureFile = Join-Path $fixtureDir 'needs-help.ps1'

            $result = Invoke-TestScriptFile -ScriptPath $script:AddCommentHelpScript -ArgumentList @(
                '-Path', $fixtureDir
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Added comment-based help|Get-CommentHelpFixtureOk'
            $updated = Get-Content -LiteralPath $fixtureFile -Raw
            $updated | Should -Match '\.SYNOPSIS'
            $updated | Should -Match 'Get-CommentHelpFixtureOk'
    }

    It 'Fails when the requested analysis path does not exist' {
        $missingPath = Join-Path (New-TestTempDirectory -Prefix 'CommentHelpMissing') 'does-not-exist'
            $result = Invoke-TestScriptFile -ScriptPath $script:AddCommentHelpScript -ArgumentList @(
                '-Path', $missingPath
            )

            $result.ExitCode | Should -Not -Be 0
            $result.Output | Should -Match 'Path|not found|does not exist|does-not-exist'
    }
}
