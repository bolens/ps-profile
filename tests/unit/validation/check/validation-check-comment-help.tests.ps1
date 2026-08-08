<#
tests/unit/validation/check/validation-check-comment-help.tests.ps1

.SYNOPSIS
    Behavioral tests for check-comment-help.ps1 using isolated fragments.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $null -eq $current.Parent) { break }
        $current = $current.Parent
    }

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CheckCommentHelpScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-comment-help.ps1'
}

Describe 'check-comment-help.ps1 execution' {
    BeforeEach {
        $script:FixtureRoot = New-TestTempDirectory -Prefix 'CommentHelp'
    }

    It 'accepts functions with help before the definition and inside the body' {
        $content = @'
<#
.SYNOPSIS
    Help before the function.
#>
function Get-BeforeHelp {
    'before'
}

function Get-BodyHelp {
    <#
    .SYNOPSIS
        Help inside the function.
    #>
    'body'
}
'@
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'documented.ps1') -Value $content -Encoding UTF8

        $output = & $script:CheckCommentHelpScript -Path $script:FixtureRoot -Verbose 2>&1 | Out-String

        $output | Should -Match 'OK: documented.ps1'
        $output | Should -Match 'All functions have comment-based help'
    }

    It 'resolves a relative fragment path from the repository root' {
        $content = @'
<#
.SYNOPSIS
    Relative-path fixture help.
#>
function Get-RelativeCommentHelpFixture {
    'documented'
}
'@
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'relative.ps1') -Value $content -Encoding UTF8
        $relativePath = [System.IO.Path]::GetRelativePath($script:TestRepoRoot, $script:FixtureRoot)

        $output = & $script:CheckCommentHelpScript -Path $relativePath 2>&1 | Out-String

        $output | Should -Match 'All functions have comment-based help'
    }

    It 'reports every undocumented function in a fragment' {
        $content = @'
function Get-FirstMissing {
    'first'
}

function Set-SecondMissing {
    'second'
}
'@
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'missing.ps1') -Value $content -Encoding UTF8

        {
            & $script:CheckCommentHelpScript -Path $script:FixtureRoot
        } | Should -Throw '*1 fragments with functions missing comment-based help*'
    }

    It 'ignores empty fragment files' {
        [System.IO.File]::WriteAllText((Join-Path $script:FixtureRoot 'empty.ps1'), '')

        $output = & $script:CheckCommentHelpScript -Path $script:FixtureRoot *>&1 | Out-String

        $output | Should -Match 'All functions have comment-based help'
    }

    It 'reports parser failures without terminating the scan' {
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'invalid.ps1') -Value 'function Get-Broken {' -Encoding UTF8

        $output = & $script:CheckCommentHelpScript -Path $script:FixtureRoot *>&1 | Out-String

        $output | Should -Match 'Failed to parse'
        $output | Should -Match 'All functions have comment-based help'
    }

    It 'rejects a missing fragment directory' {
        $missingPath = Join-Path $script:FixtureRoot 'missing'

        {
            & $script:CheckCommentHelpScript -Path $missingPath
        } | Should -Throw '*Profile fragment directory not found*'
    }
}
