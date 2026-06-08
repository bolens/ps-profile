<#
tests/unit/utility-enrich-help.tests.ps1

.SYNOPSIS
    Unit and integration tests for shallow-help enrichment utility scripts.
#>

function global:New-EnrichHelpFixtureRoot {
    return New-TestTempDirectory -Prefix 'EnrichHelpFixture'
}

function global:Invoke-EnrichHelpScript {
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
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CodeQualityPath = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality'
    $script:EnrichSynopsisScript = Join-Path $script:CodeQualityPath 'enrich-synopsis-only.ps1'
    $script:EnrichExamplesScript = Join-Path $script:CodeQualityPath 'enrich-missing-examples.ps1'
    $script:EnrichParametersScript = Join-Path $script:CodeQualityPath 'enrich-missing-parameters.ps1'
    $script:FixtureRoot = New-EnrichHelpFixtureRoot
    $script:EnrichNoopPath = New-TestTempDirectory -Prefix 'EnrichHelpNoop'
    $ConfirmPreference = 'None'

    . $script:EnrichSynopsisScript -Path @($script:EnrichNoopPath) 2>&1 | Out-Null
    . $script:EnrichExamplesScript -Path @($script:EnrichNoopPath) 2>&1 | Out-Null
    . $script:EnrichParametersScript -Path @($script:EnrichNoopPath) 2>&1 | Out-Null
}

AfterAll {
    if (Test-Path -LiteralPath $script:EnrichNoopPath) {
        Remove-Item -LiteralPath $script:EnrichNoopPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'enrich-synopsis-only.ps1' {
    Context 'Add-DescriptionToHelpBlock' {
        It 'Adds .DESCRIPTION copied from synopsis text' {
            $help = @'
.SYNOPSIS
    Adds synopsis-only description text.
.PARAMETER Name
    A name parameter.
'@

            $result = Add-DescriptionToHelpBlock -HelpBlock $help

            $result | Should -Match '(?m)^\s*\.DESCRIPTION\s*$'
            $result | Should -Match 'synopsis-only description text'
            $result | Should -Match '(?m)^\s*\.PARAMETER\s+Name'
        }

        It 'Returns the original block when .DESCRIPTION already exists' {
            $help = @'
.SYNOPSIS
    Already documented.
.DESCRIPTION
    Existing description section.
'@

            $result = Add-DescriptionToHelpBlock -HelpBlock $help
            $result | Should -Be $help
        }

        It 'Returns the original block when .SYNOPSIS is missing' {
            $help = @'
.DESCRIPTION
    Description without synopsis.
'@

            $result = Add-DescriptionToHelpBlock -HelpBlock $help
            $result | Should -Be $help
        }
    }

    Context 'File enrichment' {
        It 'Updates synopsis-only fixture functions in place' {
            $fixtureDir = Join-Path $script:FixtureRoot 'synopsis-only'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $fixtureFile = Join-Path $fixtureDir 'fixture.ps1'
            Set-Content -LiteralPath $fixtureFile -Value @'
function Get-EnrichSynopsisFixture {
    <#
    .SYNOPSIS
        Fixture synopsis for enrichment.
    .PARAMETER Name
        A name parameter.
    #>
    param(
        [string]$Name
    )
}
'@ -Encoding UTF8 -NoNewline

            $output = Invoke-EnrichHelpScript -ScriptPath $script:EnrichSynopsisScript -FixtureDirectory $fixtureDir
            $updated = Get-Content -LiteralPath $fixtureFile -Raw

            $output | Should -Match 'Updated:'
            $updated | Should -Match '(?m)^\s*\.DESCRIPTION\s*$'
            $updated | Should -Match 'Fixture synopsis for enrichment'
        }

        It 'Skips enrichment utility scripts by filename' {
            $fixtureDir = Join-Path $script:FixtureRoot 'self-exclusion-synopsis'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $utilityCopy = Join-Path $fixtureDir 'enrich-synopsis-only.ps1'
            Copy-Item -LiteralPath $script:EnrichSynopsisScript -Destination $utilityCopy -Force
            $original = Get-Content -LiteralPath $utilityCopy -Raw

            $null = Invoke-EnrichHelpScript -ScriptPath $script:EnrichSynopsisScript -FixtureDirectory $fixtureDir
            (Get-Content -LiteralPath $utilityCopy -Raw) | Should -Be $original
        }

        It 'Skips Doc*.psm1 files to avoid corrupting documentation parser sources' {
            $fixtureDir = Join-Path $script:FixtureRoot 'doc-parser-exclusion'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $docCopy = Join-Path $fixtureDir 'DocHelpParser.psm1'
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'utils' 'docs' 'modules' 'DocHelpParser.psm1') -Destination $docCopy -Force
            $original = Get-Content -LiteralPath $docCopy -Raw

            $null = Invoke-EnrichHelpScript -ScriptPath $script:EnrichSynopsisScript -FixtureDirectory $fixtureDir
            (Get-Content -LiteralPath $docCopy -Raw) | Should -Be $original
        }

        It 'Skips CommentHelp.psm1 to avoid corrupting embedded regex literals' {
            $fixtureDir = Join-Path $script:FixtureRoot 'commenthelp-exclusion'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $commentHelpCopy = Join-Path $fixtureDir 'CommentHelp.psm1'
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib' 'code-analysis' 'CommentHelp.psm1') -Destination $commentHelpCopy -Force
            $original = Get-Content -LiteralPath $commentHelpCopy -Raw

            $null = Invoke-EnrichHelpScript -ScriptPath $script:EnrichSynopsisScript -FixtureDirectory $fixtureDir
            (Get-Content -LiteralPath $commentHelpCopy -Raw) | Should -Be $original
        }
    }
}

Describe 'enrich-missing-examples.ps1' {
    Context 'Add-ExampleToHelpBlock' {
        It 'Appends .EXAMPLE when parameters are documented' {
            $help = @'
.SYNOPSIS
    Example helper.
.DESCRIPTION
    Has parameter docs but no example section.
.PARAMETER Path
    Input path.
'@

            $result = Add-ExampleToHelpBlock -HelpBlock $help -FunctionName 'Get-EnrichExampleFixture'

            $result | Should -Match '(?m)^\s*\.EXAMPLE\s*$'
            $result | Should -Match 'Get-EnrichExampleFixture'
        }

        It 'Uses Format- prefix example template' {
            $help = @'
.SYNOPSIS
    Format helper.
.PARAMETER InputObject
    JSON object.
'@

            $result = Add-ExampleToHelpBlock -HelpBlock $help -FunctionName 'Format-Json'

            $result | Should -Match 'Format-Json -InputObject'
        }

        It 'Uses ConvertFrom- prefix example template' {
            $help = @'
.SYNOPSIS
    Convert helper.
.PARAMETER InputPath
    Input path.
'@

            $result = Add-ExampleToHelpBlock -HelpBlock $help -FunctionName 'ConvertFrom-Yaml'

            $result | Should -Match 'ConvertFrom-Yaml -InputPath ./input.file'
        }

        It 'Returns unchanged when .EXAMPLE already exists' {
            $help = @'
.SYNOPSIS
    Already has example.
.PARAMETER Name
    A name.
.EXAMPLE
    Get-AlreadyDocumented -Name test
'@

            $result = Add-ExampleToHelpBlock -HelpBlock $help -FunctionName 'Get-AlreadyDocumented'
            $result | Should -Be $help
        }

        It 'Returns unchanged when .PARAMETER is missing' {
            $help = @'
.SYNOPSIS
    Synopsis only.
.DESCRIPTION
    No parameter documentation present.
'@

            $result = Add-ExampleToHelpBlock -HelpBlock $help -FunctionName 'Get-NoParameterDocs'
            $result | Should -Be $help
        }
    }

    Context 'File enrichment' {
        It 'Adds .EXAMPLE to fixture functions with parameter docs' {
            $fixtureDir = Join-Path $script:FixtureRoot 'missing-examples'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $fixtureFile = Join-Path $fixtureDir 'fixture.ps1'
            Set-Content -LiteralPath $fixtureFile -Value @'
function Get-EnrichExampleFixture {
    <#
    .SYNOPSIS
        Example enrichment fixture.
    .DESCRIPTION
        Parameter docs exist but example is missing.
    .PARAMETER Path
        Input path.
    #>
    param(
        [string]$Path
    )
}
'@ -Encoding UTF8 -NoNewline

            $output = Invoke-EnrichHelpScript -ScriptPath $script:EnrichExamplesScript -FixtureDirectory $fixtureDir
            $updated = Get-Content -LiteralPath $fixtureFile -Raw

            $output | Should -Match 'Updated:'
            $updated | Should -Match '(?m)^\s*\.EXAMPLE\s*$'
            $updated | Should -Match 'Get-EnrichExampleFixture'
        }
    }
}

Describe 'enrich-missing-parameters.ps1' {
    Context 'Get-ParameterHelpLines' {
        It 'Builds .PARAMETER lines from a parsed function AST' {
            $functionDefinition = @'
function Get-ParameterHelpAstFixture {
    param(
        [string]$First,
        [int]$Second
    )
}
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                $functionDefinition,
                [ref]$null,
                [ref]$null)
            $funcAst = $ast.Find({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)

            $lines = Get-ParameterHelpLines -FuncAst $funcAst

            $lines | Should -Contain '.PARAMETER First'
            $lines | Should -Contain '.PARAMETER Second'
            ($lines -join "`n") | Should -Match 'First parameter\.'
        }

        It 'Returns an empty list when the function has no param block' {
            $functionDefinition = 'function Get-NoParamBlockFixture { "ok" }'
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                $functionDefinition,
                [ref]$null,
                [ref]$null)
            $funcAst = $ast.Find({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)

            Get-ParameterHelpLines -FuncAst $funcAst | Should -Be @()
        }
    }

    Context 'Add-ParameterDocsToHelpBlock' {
        It 'Appends .PARAMETER and .EXAMPLE when both are missing' {
            $functionDefinition = @'
function Invoke-EnrichParameterFixture {
    <# .SYNOPSIS Summary. .DESCRIPTION Details. #>
    param(
        [string]$Command
    )
}
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                $functionDefinition,
                [ref]$null,
                [ref]$null)
            $funcAst = $ast.Find({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)
            $help = @'
.SYNOPSIS
    Parameter enrichment fixture.
.DESCRIPTION
    Missing parameter and example sections.
'@

            $result = Add-ParameterDocsToHelpBlock -HelpBlock $help -FunctionName 'Invoke-EnrichParameterFixture' -FuncAst $funcAst

            $result | Should -Match '(?m)^\s*\.PARAMETER\s+Command'
            $result | Should -Match '(?m)^\s*\.EXAMPLE\s*$'
            $result | Should -Match "Invoke-EnrichParameterFixture -Arguments @\('-h'\)"
        }

        It 'Returns unchanged when parameter docs and example already exist' {
            $functionDefinition = 'function Get-AlreadyDocumented { param([string]$Name) }'
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                $functionDefinition,
                [ref]$null,
                [ref]$null)
            $funcAst = $ast.Find({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)
            $help = @'
.SYNOPSIS
    Complete help.
.DESCRIPTION
    Fully documented parameter and example sections.
.PARAMETER Name
    A name.
.EXAMPLE
    Get-AlreadyDocumented -Name test
'@

            $result = Add-ParameterDocsToHelpBlock -HelpBlock $help -FunctionName 'Get-AlreadyDocumented' -FuncAst $funcAst
            $result | Should -Be $help
        }

        It 'Returns unchanged when the function has no parameters' {
            $functionDefinition = 'function Get-NoParametersFixture { "ok" }'
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                $functionDefinition,
                [ref]$null,
                [ref]$null)
            $funcAst = $ast.Find({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)
            $help = @'
.SYNOPSIS
    No parameters.
.DESCRIPTION
    Function without a param block.
'@

            $result = Add-ParameterDocsToHelpBlock -HelpBlock $help -FunctionName 'Get-NoParametersFixture' -FuncAst $funcAst
            $result | Should -Be $help
        }
    }

    Context 'File enrichment' {
        It 'Updates fixture functions missing parameter documentation' {
            $fixtureDir = Join-Path $script:FixtureRoot 'missing-parameters'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $fixtureFile = Join-Path $fixtureDir 'fixture.ps1'
            Set-Content -LiteralPath $fixtureFile -Value @'
function Invoke-EnrichParameterFixture {
    <#
    .SYNOPSIS
        Parameter enrichment fixture.
    .DESCRIPTION
        Missing parameter and example sections.
    #>
    param(
        [string]$Command
    )
}
'@ -Encoding UTF8 -NoNewline

            $output = Invoke-EnrichHelpScript -ScriptPath $script:EnrichParametersScript -FixtureDirectory $fixtureDir
            $updated = Get-Content -LiteralPath $fixtureFile -Raw

            $output | Should -Match 'Updated:'
            $updated | Should -Match '(?m)^\s*\.PARAMETER\s+Command'
            $updated | Should -Match '(?m)^\s*\.EXAMPLE\s*$'
            $updated | Should -Match 'Invoke-EnrichParameterFixture'
        }

        It 'Enriches multiple functions in one file without corrupting offsets' {
            $fixtureDir = Join-Path $script:FixtureRoot 'multi-function'
            New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
            $fixtureFile = Join-Path $fixtureDir 'fixture.ps1'
            Set-Content -LiteralPath $fixtureFile -Value @'
function Get-EnrichFirstFixture {
    <#
    .SYNOPSIS
        First fixture function.
    .DESCRIPTION
        Missing parameter and example sections.
    #>
    param([string]$First)
}

function Get-EnrichSecondFixture {
    <#
    .SYNOPSIS
        Second fixture function.
    .DESCRIPTION
        Missing parameter and example sections.
    #>
    param([string]$Second)
}
'@ -Encoding UTF8 -NoNewline

            $null = Invoke-EnrichHelpScript -ScriptPath $script:EnrichParametersScript -FixtureDirectory $fixtureDir
            $updated = Get-Content -LiteralPath $fixtureFile -Raw

            $updated | Should -Match '(?m)^\s*\.PARAMETER\s+First'
            $updated | Should -Match '(?m)^\s*\.PARAMETER\s+Second'
            $updated | Should -Match 'Get-EnrichFirstFixture'
            $updated | Should -Match 'Get-EnrichSecondFixture'
        }
    }
}
