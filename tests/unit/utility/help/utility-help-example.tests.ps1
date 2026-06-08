<#
tests/unit/utility-help-example.tests.ps1

.SYNOPSIS
    Unit tests for bare-example improvement and cleanup utility scripts.
#>

function global:New-HelpExampleFixtureRoot {
    return New-TestTempDirectory -Prefix 'HelpExampleFixture'
}

function global:Get-HelpExampleFunctionAst {
    param([string]$FunctionDefinition)

    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $FunctionDefinition,
        [ref]$null,
        [ref]$null)

    return $ast.Find({
            $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
}

function global:Invoke-HelpExampleScript {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [Parameter(Mandatory)]
        [string]$FixtureDirectory
    )

    Push-Location $FixtureDirectory
    try {
        & pwsh -NoProfile -File $ScriptPath -Path '.' 2>&1 | Out-String
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
    $script:CodeQualityPath = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality'
    $script:ImproveBareExamplesScript = Join-Path $script:CodeQualityPath 'improve-bare-examples.ps1'
    $script:CleanupHelpExamplesScript = Join-Path $script:CodeQualityPath 'cleanup-help-examples.ps1'
    $script:ReorderCommentHelpScript = Join-Path $script:CodeQualityPath 'reorder-comment-help.ps1'
    $script:FixtureRoot = New-HelpExampleFixtureRoot
    $script:HelpExampleNoopPath = New-TestTempDirectory -Prefix 'HelpExampleNoop'
    $ConfirmPreference = 'None'

    . $script:ImproveBareExamplesScript -Path @($script:HelpExampleNoopPath) 2>&1 | Out-Null
    . $script:ReorderCommentHelpScript -Path @($script:HelpExampleNoopPath) 2>&1 | Out-Null
}

AfterAll {
    if (Test-Path -LiteralPath $script:HelpExampleNoopPath) {
        Remove-Item -LiteralPath $script:HelpExampleNoopPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'improve-bare-examples.ps1' {
    Context 'Get-ExampleValueForParameter' {
        It 'Returns mapped values for known parameter names' {
            Get-ExampleValueForParameter -Name 'FilePath' -TypeName 'string' | Should -Be './Taskfile.yml'
            Get-ExampleValueForParameter -Name 'Arguments' -TypeName 'object[]' | Should -Be "@('--help')"
            Get-ExampleValueForParameter -Name 'ReferenceTasks' -TypeName 'hashtable' | Should -Be '$refTasks'
        }

        It 'Infers collection and hashtable defaults for unknown names' {
            Get-ExampleValueForParameter -Name 'CustomList' -TypeName 'string[]' | Should -Be '@()'
            Get-ExampleValueForParameter -Name 'CustomMap' -TypeName 'hashtable' | Should -Be '@{}'
        }
    }

    Context 'Get-FunctionExampleLine' {
        It 'Includes mandatory parameters in the example line' {
            $funcAst = Get-HelpExampleFunctionAst @'
function Get-BareExampleFixture {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [ValidateSet('taskfile', 'makefile')]
        [string]$FileType
    )
}
'@

            $line = Get-FunctionExampleLine -FuncAst $funcAst

            $line | Should -Match 'Get-BareExampleFixture'
            $line | Should -Match '-FilePath ./Taskfile.yml'
            $line | Should -Match "-FileType 'taskfile'"
        }

        It 'Uses Invoke help splatting when only Arguments is present' {
            $funcAst = Get-HelpExampleFunctionAst @'
function Invoke-BareExampleFixture {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Arguments
    )
}
'@

            Get-FunctionExampleLine -FuncAst $funcAst | Should -Be '    Invoke-BareExampleFixture @(''--help'')'
        }

        It 'Uses bare function name for non-Invoke wrappers with Arguments' {
            $funcAst = Get-HelpExampleFunctionAst @'
function Start-BareExampleFixture {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
}
'@

            Get-FunctionExampleLine -FuncAst $funcAst | Should -Be '    Start-BareExampleFixture'
        }

        It 'Uses verb-specific defaults when no parameters are declared' {
            $funcAst = Get-HelpExampleFunctionAst 'function Install-BareExampleFixture { param() }'

            Get-FunctionExampleLine -FuncAst $funcAst | Should -Be '    Install-BareExampleFixture ''package-name'''
        }

        It 'Includes optional parameters when no mandatory parameters exist' {
            $funcAst = Get-HelpExampleFunctionAst @'
function Find-BareExampleFixture {
    param(
        [string]$Pattern,
        [switch]$CaseSensitive,
        [int]$MaxResults = 20
    )
}
'@

            $line = Get-FunctionExampleLine -FuncAst $funcAst

            $line | Should -Match 'Find-BareExampleFixture'
            $line | Should -Match "-Pattern 'search-term'"
            $line | Should -Match '-MaxResults 1'
            $line | Should -Not -Match 'CaseSensitive'
        }
    }

    Context 'File enrichment' {
        It 'Upgrades bare function-name examples in place' {
            $fixtureDir = Join-Path $script:FixtureRoot 'bare-example'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $fixtureFile = Join-Path $fixtureDir 'fixture.ps1'
            Set-Content -LiteralPath $fixtureFile -Value @'
function Get-BareExampleFixture {
    <#
    .SYNOPSIS
        Bare example fixture.
    .DESCRIPTION
        Has a bare example line to upgrade.
    .PARAMETER Path
        Input path.
    .EXAMPLE
        Get-BareExampleFixture
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
}
'@ -Encoding UTF8 -NoNewline

            $output = Invoke-HelpExampleScript -ScriptPath $script:ImproveBareExamplesScript -FixtureDirectory $fixtureDir
            $updated = Get-Content -LiteralPath $fixtureFile -Raw

            $output | Should -Match 'Updated:'
            $updated | Should -Match 'Get-BareExampleFixture -Path ./path'
            $updated | Should -Not -Match "(?m)^\s*\.EXAMPLE\s*\r?\n\s*Get-BareExampleFixture\s*$"
        }

        It 'Leaves already-specific examples unchanged' {
            $fixtureDir = Join-Path $script:FixtureRoot 'specific-example'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $fixtureFile = Join-Path $fixtureDir 'fixture.ps1'
            $original = @'
function Get-SpecificExampleFixture {
    <#
    .SYNOPSIS
        Specific example fixture.
    .DESCRIPTION
        Already has a useful example.
    .PARAMETER Path
        Input path.
    .EXAMPLE
        Get-SpecificExampleFixture -Path ./custom
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
}
'@
            Set-Content -LiteralPath $fixtureFile -Value $original -Encoding UTF8 -NoNewline

            $null = Invoke-HelpExampleScript -ScriptPath $script:ImproveBareExamplesScript -FixtureDirectory $fixtureDir

            (Get-Content -LiteralPath $fixtureFile -Raw) | Should -Be $original
        }

        It 'Skips utility scripts by filename' {
            $fixtureDir = Join-Path $script:FixtureRoot 'self-exclusion-improve'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $utilityCopy = Join-Path $fixtureDir 'improve-bare-examples.ps1'
            Copy-Item -LiteralPath $script:ImproveBareExamplesScript -Destination $utilityCopy -Force
            $original = Get-Content -LiteralPath $utilityCopy -Raw

            $null = Invoke-HelpExampleScript -ScriptPath $script:ImproveBareExamplesScript -FixtureDirectory $fixtureDir
            (Get-Content -LiteralPath $utilityCopy -Raw) | Should -Be $original
        }
    }
}

Describe 'reorder-comment-help.ps1' {
    Context 'Section normalization' {
        It 'Detects when parameter sections follow examples' {
            $help = @'
.SYNOPSIS
    Reorder fixture.
.DESCRIPTION
    Example appears before parameter docs.
.EXAMPLE
    Get-ReorderFixture
.PARAMETER Name
    A name.
'@

            Test-HelpNeedsReorder -Inner $help | Should -Be $true
        }

        It 'Moves parameter sections before examples' {
            $help = @'
.SYNOPSIS
    Reorder fixture.
.DESCRIPTION
    Example appears before parameter docs.
.EXAMPLE
    Get-ReorderFixture
.PARAMETER Name
    A name.
'@

            $result = Normalize-HelpBlockInner -Inner $help

            $result | Should -Match '(?ms)\.PARAMETER\s+Name[\s\S]*\.EXAMPLE'
            $result | Should -Not -Match '(?ms)\.EXAMPLE[\s\S]*\.PARAMETER\s+Name'
        }

        It 'Leaves already-ordered help unchanged' {
            $help = @'
.SYNOPSIS
    Ordered fixture.
.DESCRIPTION
    Parameter docs already precede examples.
.PARAMETER Name
    A name.
.EXAMPLE
    Get-OrderedFixture -Name test
'@

            Normalize-HelpBlockInner -Inner $help | Should -Be $help
        }
    }

    Context 'File reordering' {
        It 'Reorders misordered help blocks in fixture files' {
            $fixtureDir = Join-Path $script:FixtureRoot 'reorder-help'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $fixtureFile = Join-Path $fixtureDir 'fixture.ps1'
            Set-Content -LiteralPath $fixtureFile -Value @'
function Get-ReorderFixture {
    <#
    .SYNOPSIS
        Reorder fixture function.
    .DESCRIPTION
        Example appears before parameter docs.
    .EXAMPLE
        Get-ReorderFixture
    .PARAMETER Name
        A name.
    #>
    param([string]$Name)
}
'@ -Encoding UTF8 -NoNewline

            $output = Invoke-HelpExampleScript -ScriptPath $script:ReorderCommentHelpScript -FixtureDirectory $fixtureDir
            $updated = Get-Content -LiteralPath $fixtureFile -Raw

            $output | Should -Match 'Reordered:'
            $updated | Should -Match '(?ms)\.PARAMETER\s+Name[\s\S]*\.EXAMPLE'
        }
    }
}

Describe 'cleanup-help-examples.ps1' {
    Context 'File cleanup' {
        It 'Removes redundant --help example when a better example follows' {
            $fixtureDir = Join-Path $script:FixtureRoot 'cleanup-duplicate'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $fixtureFile = Join-Path $fixtureDir 'fixture.ps1'
            Set-Content -LiteralPath $fixtureFile -Value @'
function Start-CleanupExampleFixture {
    <#
    .SYNOPSIS
        Cleanup duplicate example fixture.
    .DESCRIPTION
        Contains a redundant --help example.
    .PARAMETER Arguments
        Remaining arguments.
    .EXAMPLE
        Start-CleanupExampleFixture -Arguments @('--help')
    .EXAMPLE
        Start-CleanupExampleFixture --port 3000
    #>
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
}
'@ -Encoding UTF8 -NoNewline

            $output = Invoke-HelpExampleScript -ScriptPath $script:CleanupHelpExamplesScript -FixtureDirectory $fixtureDir
            $updated = Get-Content -LiteralPath $fixtureFile -Raw

            $output | Should -Match 'Cleaned:'
            $updated | Should -Not -Match "-Arguments @\('--help'\)"
            $updated | Should -Match 'Start-CleanupExampleFixture --port 3000'
        }

        It 'Downgrades standalone --help examples to bare function names' {
            $fixtureDir = Join-Path $script:FixtureRoot 'cleanup-standalone'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $fixtureFile = Join-Path $fixtureDir 'fixture.ps1'
            Set-Content -LiteralPath $fixtureFile -Value @'
function Build-CleanupExampleFixture {
    <#
    .SYNOPSIS
        Cleanup standalone example fixture.
    .DESCRIPTION
        Contains only a --help example.
    .PARAMETER Arguments
        Remaining arguments.
    .EXAMPLE
        Build-CleanupExampleFixture -Arguments @('--help')
    #>
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
}
'@ -Encoding UTF8 -NoNewline

            $output = Invoke-HelpExampleScript -ScriptPath $script:CleanupHelpExamplesScript -FixtureDirectory $fixtureDir
            $updated = Get-Content -LiteralPath $fixtureFile -Raw

            $output | Should -Match 'Cleaned:'
            $updated | Should -Match "(?m)^\s*\.EXAMPLE\s*\r?\n\s*Build-CleanupExampleFixture\s*$"
            $updated | Should -Not -Match "-Arguments @\('--help'\)"
        }

        It 'Leaves files without --help examples unchanged' {
            $fixtureDir = Join-Path $script:FixtureRoot 'cleanup-noop'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $fixtureFile = Join-Path $fixtureDir 'fixture.ps1'
            $original = @'
function Get-CleanupNoopFixture {
    <#
    .SYNOPSIS
        Cleanup noop fixture.
    .EXAMPLE
        Get-CleanupNoopFixture -Path ./custom
    #>
    param([string]$Path)
}
'@
            Set-Content -LiteralPath $fixtureFile -Value $original -Encoding UTF8 -NoNewline

            $output = Invoke-HelpExampleScript -ScriptPath $script:CleanupHelpExamplesScript -FixtureDirectory $fixtureDir

            $output | Should -Not -Match 'Cleaned:'
            (Get-Content -LiteralPath $fixtureFile -Raw) | Should -Be $original
        }
    }
}
