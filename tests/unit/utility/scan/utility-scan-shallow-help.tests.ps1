<#
tests/unit/utility-scan-shallow-help.tests.ps1

.SYNOPSIS
    Behavioral unit tests for scan-shallow-help.ps1 shallow help detection.
#>

function global:New-ShallowHelpFixtureDirectory {
    param(
        [string]$Prefix = 'ShallowHelpFixture'
    )

    $root = New-TestTempDirectory -Prefix $Prefix
    $fixturesDir = Join-Path $root 'fixtures'
    New-Item -ItemType Directory -Path $fixturesDir -Force | Out-Null

    return @{
        Root        = $root
        FixturesDir = $fixturesDir
    }
}

function global:Invoke-ScanShallowHelp {
    param(
        [Parameter(Mandatory)]
        [string]$FixtureDirectory,

        [int]$MinIssues = 1
    )

    Push-Location $FixtureDirectory
    try {
    & pwsh -NoProfile -File $script:ScanShallowHelpScript -Path 'fixtures' -MinIssues $MinIssues 2>&1 | Out-String
    }
    finally {
        Pop-Location
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
    $script:ScanShallowHelpScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'scan-shallow-help.ps1'
    $script:NoopScanPath = Join-Path ([System.IO.Path]::GetTempPath()) ('ScanShallowNoop-{0}' -f [System.Guid]::NewGuid())
    New-Item -ItemType Directory -Path $script:NoopScanPath -Force | Out-Null
    . $script:ScanShallowHelpScript -Path $script:NoopScanPath -MinIssues 1 2>&1 | Out-Null
    $ConfirmPreference = 'None'
}

AfterAll {
    if (Test-Path -LiteralPath $script:NoopScanPath) {
        Remove-Item -LiteralPath $script:NoopScanPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'scan-shallow-help.ps1 helper functions' {
    Context 'Get-ShallowHelpIssues' {
        It 'Detects synopsis-only and missing-examples together' {
            $issues = Get-ShallowHelpIssues -HelpContent @'
.SYNOPSIS
    Synopsis only fixture.
.PARAMETER Name
    A name parameter.
'@ -ParamCount 1

            $issueText = $issues -join ', '
            $issueText | Should -Match 'synopsis-only'
            $issueText | Should -Match 'missing-examples'
        }

        It 'Detects short-description when description text is too brief' {
            $issues = Get-ShallowHelpIssues -HelpContent @'
.SYNOPSIS
    Short description fixture.
.DESCRIPTION
    Too short.
'@ -ParamCount 0

            $issues | Should -Contain 'short-description'
        }

        It 'Returns no issues for complete help with parameters and example' {
            $issues = Get-ShallowHelpIssues -HelpContent @'
.SYNOPSIS
    Complete help fixture.
.DESCRIPTION
    Fully documented help block for scan testing.
.PARAMETER Name
    A name parameter.
.EXAMPLE
    Get-CompleteHelpFixture -Name test
'@ -ParamCount 1

            @($issues) | Should -Be @()
        }
    }

    Context 'Get-FunctionHelpContent' {
        It 'Reads help from inside the function body' {
            $content = @'
function Get-BodyHelpFixture {
    <#
    .SYNOPSIS
        Body help fixture.
    .DESCRIPTION
        Help block located inside the function body.
    #>
    param()
}
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $funcAst = $ast.Find({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)

            $help = Get-FunctionHelpContent -Content $content -FuncAst $funcAst

            $help | Should -Match 'Body help fixture'
            $help | Should -Match '\.DESCRIPTION'
        }

        It 'Reads help from the comment block before the function' {
            $content = @'
<#
.SYNOPSIS
    Before-function help fixture.
.DESCRIPTION
    Help block located before the function definition.
#>
function Get-BeforeHelpFixture {
    param()
}
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $funcAst = $ast.Find({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)

            $help = Get-FunctionHelpContent -Content $content -FuncAst $funcAst

            $help | Should -Match 'Before-function help fixture'
        }
    }
}

Describe 'scan-shallow-help.ps1 execution' {
    It 'Reports shallow help issues for fixture functions with incomplete documentation' {
        $fixture = New-ShallowHelpFixtureDirectory
            Set-Content -LiteralPath (Join-Path $fixture.FixturesDir 'shallow.ps1') -Value @'
function Get-ShallowHelpFixture {
    <#
    .SYNOPSIS
        Synopsis only fixture.
    .PARAMETER Name
        A name parameter.
    #>
    param(
        [string]$Name
    )
}
'@ -Encoding UTF8

            $output = Invoke-ScanShallowHelp -FixtureDirectory $fixture.Root

            $output | Should -Match 'Get-ShallowHelpFixture'
            $output | Should -Match 'synopsis-only|missing-parameter-docs|missing-examples'
            $output | Should -Match 'Total shallow \(1\+ issues\): [1-9]'
    }

    It 'Reports zero shallow issues for fully documented fixture functions' {
        $fixture = New-ShallowHelpFixtureDirectory -Prefix 'ShallowHelpComplete'
            Set-Content -LiteralPath (Join-Path $fixture.FixturesDir 'complete.ps1') -Value @'
function Get-CompleteHelpFixture {
    <#
    .SYNOPSIS
        Complete help fixture.
    .DESCRIPTION
        Fully documented help block for scan testing.
    .PARAMETER Name
        A name parameter.
    .EXAMPLE
        Get-CompleteHelpFixture -Name test
    #>
    param(
        [string]$Name
    )
}
'@ -Encoding UTF8

            $output = Invoke-ScanShallowHelp -FixtureDirectory $fixture.Root

            $output | Should -Not -Match 'Get-CompleteHelpFixture'
            $output | Should -Match 'Total shallow \(1\+ issues\): 0'
    }

    It 'Detects help blocks inside function bodies' {
        $fixture = New-ShallowHelpFixtureDirectory -Prefix 'ShallowHelpBody'
            Set-Content -LiteralPath (Join-Path $fixture.FixturesDir 'body-help.ps1') -Value @'
function Get-BodyHelpScanFixture {
    <#
    .SYNOPSIS
        Body help scan fixture.
    .PARAMETER Value
        A value parameter.
    #>
    param(
        [string]$Value
    )
}
'@ -Encoding UTF8

            $output = Invoke-ScanShallowHelp -FixtureDirectory $fixture.Root

            $output | Should -Match 'Get-BodyHelpScanFixture'
            $output | Should -Match 'synopsis-only|missing-examples'
    }

    It 'Skips Doc*.psm1 parser modules during scans' {
        $fixture = New-ShallowHelpFixtureDirectory -Prefix 'ShallowHelpDocSkip'
            Set-Content -LiteralPath (Join-Path $fixture.FixturesDir 'DocHelpParser.psm1') -Value @'
function Normalize-CommentHelpBlock {
    <#
    .SYNOPSIS
        Parser copy with incomplete help.
    .PARAMETER CommentBlock
        Comment block text.
    #>
    param(
        [string]$CommentBlock
    )
}
'@ -Encoding UTF8

            $output = Invoke-ScanShallowHelp -FixtureDirectory $fixture.Root

            $output | Should -Not -Match 'Normalize-CommentHelpBlock'
            $output | Should -Match 'Total shallow \(1\+ issues\): 0'
    }

    It 'Skips enrichment utility scripts by filename during scans' {
        $fixture = New-ShallowHelpFixtureDirectory -Prefix 'ShallowHelpExclusion'
            Set-Content -LiteralPath (Join-Path $fixture.FixturesDir 'enrich-missing-examples.ps1') -Value @'
function Add-ExampleToHelpBlock {
    <#
    .SYNOPSIS
        Utility copy with incomplete help.
    .PARAMETER HelpBlock
        Help block text.
    #>
    param(
        [string]$HelpBlock
    )
}
'@ -Encoding UTF8

            $output = Invoke-ScanShallowHelp -FixtureDirectory $fixture.Root

            $output | Should -Not -Match 'Add-ExampleToHelpBlock'
            $output | Should -Match 'Total shallow \(1\+ issues\): 0'
    }

    It 'Reports zero shallow issues when the scan directory contains no PowerShell files' {
        $emptyDir = New-TestTempDirectory -Prefix 'ShallowHelpEmptyDir'
        $output = & pwsh -NoProfile -File $script:ScanShallowHelpScript -Path $emptyDir -MinIssues 1 2>&1 | Out-String
        $output | Should -Match 'Total shallow \(1\+ issues\): 0'
    }
}
