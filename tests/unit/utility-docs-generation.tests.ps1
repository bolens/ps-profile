#
# Tests for the documentation generation helpers.
#

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:ScriptsUtilsDocsPath = Get-TestPath -RelativePath 'scripts\utils\docs' -StartPath $PSScriptRoot -EnsureExists
    $script:CommentBlockRegex = [regex]::new('<#[\s\S]*?#>', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'DocsGeneration'
}

Describe 'Documentation generation' {
    Context 'Comment parsing' {
        It 'parses comment-based help correctly' {
            $testFunction = @'
<#
.SYNOPSIS
    Test function for documentation
.DESCRIPTION
    This is a test function with parameters.
.PARAMETER Name
    The name parameter
.PARAMETER Value
    The value parameter
.EXAMPLE
    Test-Function -Name "test" -Value 123
#>
function Test-Function {
    param($Name, $Value)
}
'@

            $tempFile = Join-Path $script:TestTempRoot 'test_function.ps1'
            Set-Content -Path $tempFile -Value $testFunction -Encoding UTF8

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($tempFile, [ref]$null, [ref]$null)
            $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

            @($functionAsts).Count | Should -Be 1
            $functionAsts[0].Name | Should -Be 'Test-Function'
        }

        It 'handles functions without parameters' {
            $testFunction = @'
<#
.SYNOPSIS
    Simple function
.DESCRIPTION
    A function with no parameters
.EXAMPLE
    Simple-Function
#>
function Simple-Function { }
'@

            $tempFile = Join-Path $script:TestTempRoot 'simple_function.ps1'
            Set-Content -Path $tempFile -Value $testFunction -Encoding UTF8

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($tempFile, [ref]$null, [ref]$null)
            $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

            @($functionAsts).Count | Should -Be 1
            $functionAsts[0].Name | Should -Be 'Simple-Function'
        }

        It 'extracts synopsis from comment-based help' {
            $testFunction = @'
<#
.SYNOPSIS
    This is a test synopsis
.DESCRIPTION
    Description here
#>
function Test-Synopsis { }
'@

            $tempFile = Join-Path $script:TestTempRoot 'test_synopsis.ps1'
            Set-Content -Path $tempFile -Value $testFunction -Encoding UTF8

            $content = Get-Content $tempFile -Raw
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($tempFile, [ref]$null, [ref]$null)
            $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

            @($functionAsts).Count | Should -Be 1
            $functionAst = $functionAsts[0]
            $startOffset = $functionAst.Extent.StartOffset
            $leadingText = $content.Substring(0, $startOffset)
            $commentMatches = $script:CommentBlockRegex.Matches($leadingText)

            @($commentMatches).Count | Should -Be 1
            $helpContent = $commentMatches[-1].Value -replace '^<#\s*', '' -replace '\s*#>$', ''

            if ($helpContent -match '(?s)\.SYNOPSIS\s*\n\s*(.+?)\n\s*\.DESCRIPTION') {
                $synopsis = $matches[1].Trim()
                $synopsis | Should -Be 'This is a test synopsis'
            }
        }
    }

    Context 'Set-AgentModeFunction parsing' {
        It 'extracts documentation from Set-AgentModeFunction registrations' {
            $docsModulesPath = Join-Path $script:ScriptsUtilsDocsPath 'modules'
            Import-Module (Join-Path $docsModulesPath 'DocParser.psm1') -DisableNameChecking -Force

            $testFile = Join-Path $script:TestTempRoot 'agent_mode_function.ps1'
            $testContent = @'
<#
.SYNOPSIS
    Shows commit history.
.DESCRIPTION
    Displays the commit log for the repository.
#>
Set-AgentModeFunction -Name 'Get-GitLog' -Body {
    param([Parameter(ValueFromRemainingArguments = $true)] $RemainingArgs)
    git log @RemainingArgs
} | Out-Null
'@
            Set-Content -Path $testFile -Value $testContent -Encoding UTF8

            $testDir = Split-Path -Parent $testFile
            $parsed = Get-DocumentedCommands -ProfilePath $testDir
            $function = $parsed.Functions | Where-Object { $_.Name -eq 'Get-GitLog' } | Select-Object -First 1

            $function | Should -Not -BeNullOrEmpty
            $function.Synopsis | Should -Match 'commit history'
            $function.Description | Should -Match 'commit log'
            $function.File | Should -Be $testFile
            $function.Signature | Should -Match 'Get-GitLog'
            $function.Signature | Should -Match '\$RemainingArgs'
        }

        It 'prefers AST function definitions over Set-AgentModeFunction duplicates' {
            $docsModulesPath = Join-Path $script:ScriptsUtilsDocsPath 'modules'
            Import-Module (Join-Path $docsModulesPath 'DocParser.psm1') -DisableNameChecking -Force

            $testFile = Join-Path $script:TestTempRoot 'agent_mode_duplicate.ps1'
            $testContent = @'
<#
.SYNOPSIS
    AST-defined synopsis.
.DESCRIPTION
    AST-defined description.
#>
function Get-DuplicateSample {
    [CmdletBinding()]
    param()
}

<#
.SYNOPSIS
    Agent-mode synopsis.
.DESCRIPTION
    Agent-mode description.
#>
Set-AgentModeFunction -Name 'Get-DuplicateSample' -Body { 'agent' }
'@
            Set-Content -Path $testFile -Value $testContent -Encoding UTF8

            $testDir = Split-Path -Parent $testFile
            $parsed = Get-DocumentedCommands -ProfilePath $testDir
            @($parsed.Functions | Where-Object { $_.Name -eq 'Get-DuplicateSample' }).Count | Should -Be 1
            ($parsed.Functions | Where-Object { $_.Name -eq 'Get-DuplicateSample' }).Synopsis | Should -Match 'AST-defined synopsis'
        }

        It 'generates markdown for Set-AgentModeFunction registrations' {
            $tempDir = Join-Path $script:TestTempRoot 'docs_agent_mode'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            $testProfileDir = Join-Path $tempDir 'profile.d'
            New-Item -ItemType Directory -Path $testProfileDir -Force | Out-Null

            $testFileContent = @'
<#
.SYNOPSIS
    Shows commit history.
.DESCRIPTION
    Displays the commit log for the repository.
#>
Set-AgentModeFunction -Name 'Get-GitLog' -Body {
    param([Parameter(ValueFromRemainingArguments = $true)] $RemainingArgs)
    git log @RemainingArgs
} | Out-Null
'@
            $testFile = Join-Path $testProfileDir 'git-basic.ps1'
            Set-Content -Path $testFile -Value $testFileContent -Encoding UTF8

            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            $outputPath = Join-Path $tempDir 'api'
            & $scriptPath -OutputPath $outputPath -ProfilePath $testProfileDir 2>&1 | Out-Null

            $functionDocPath = Join-Path $outputPath 'functions' 'Get-GitLog.md'
            Test-Path $functionDocPath | Should -Be $true

            $content = Get-Content $functionDocPath -Raw
            $content | Should -Match 'Get-GitLog'
            $content | Should -Match 'Shows commit history'
            $content | Should -Match 'git-basic.ps1'
        }

        It 'extracts documentation from Register-LazyFunction single-line comments' {
            $docsModulesPath = Join-Path $script:ScriptsUtilsDocsPath 'modules'
            Import-Module (Join-Path $docsModulesPath 'DocParser.psm1') -DisableNameChecking -Force

            $testFile = Join-Path $script:TestTempRoot 'register_lazy_function.ps1'
            $testContent = @'
# Git clone - clone a repository
Register-LazyFunction -Name 'Invoke-GitClone' -Initializer { $null } -Alias 'gcl'
'@
            Set-Content -Path $testFile -Value $testContent -Encoding UTF8

            $parsed = Get-DocumentedCommands -ProfilePath (Split-Path -Parent $testFile)
            $function = $parsed.Functions | Where-Object { $_.Name -eq 'Invoke-GitClone' } | Select-Object -First 1

            $function | Should -Not -BeNullOrEmpty
            $function.Synopsis | Should -Match 'Git clone'
        }

        It 'extracts documentation from inline trailing comments on Set-AgentModeFunction' {
            $docsModulesPath = Join-Path $script:ScriptsUtilsDocsPath 'modules'
            Import-Module (Join-Path $docsModulesPath 'DocParser.psm1') -DisableNameChecking -Force

            $testFile = Join-Path $script:TestTempRoot 'inline_agent_mode_function.ps1'
            $testContent = @'
function Ensure-ExampleHelper {
    $null = Set-AgentModeFunction -Name 'Invoke-GitClone' -Body { git clone @args } # Git clone - clone a repository
}
'@
            Set-Content -Path $testFile -Value $testContent -Encoding UTF8

            $parsed = Get-DocumentedCommands -ProfilePath (Split-Path -Parent $testFile)
            $function = $parsed.Functions | Where-Object { $_.Name -eq 'Invoke-GitClone' } | Select-Object -First 1

            $function | Should -Not -BeNullOrEmpty
            $function.Synopsis | Should -Match 'Git clone'
        }

        It 'extracts documentation from Set-Item Function: registrations with single-line comments' {
            $docsModulesPath = Join-Path $script:ScriptsUtilsDocsPath 'modules'
            Import-Module (Join-Path $docsModulesPath 'DocParser.psm1') -DisableNameChecking -Force

            $testFile = Join-Path $script:TestTempRoot 'set_item_function.ps1'
            $testContent = @'
# Git stash - stash changes
if (-not (Test-Path Function:Save-GitStash)) {
    Set-Item -Path Function:Save-GitStash -Value { git stash @args } -Force | Out-Null
}
'@
            Set-Content -Path $testFile -Value $testContent -Encoding UTF8

            $parsed = Get-DocumentedCommands -ProfilePath (Split-Path -Parent $testFile)
            $function = $parsed.Functions | Where-Object { $_.Name -eq 'Save-GitStash' } | Select-Object -First 1

            $function | Should -Not -BeNullOrEmpty
            $function.Synopsis | Should -Match 'Git stash'
        }

        It 'resolves help from file-level block comments for grouped New-Item registrations' {
            $docsModulesPath = Join-Path $script:ScriptsUtilsDocsPath 'modules'
            Import-Module (Join-Path $docsModulesPath 'DocParser.psm1') -DisableNameChecking -Force

            $testProfileDir = Join-Path $script:TestTempRoot 'file_level_help_profile'
            New-Item -ItemType Directory -Path $testProfileDir -Force | Out-Null
            $testFile = Join-Path $testProfileDir 'ssh.ps1'
            $testContent = @'
<#
.SYNOPSIS
    SSH agent and key management helpers.
.DESCRIPTION
    Provides functions and aliases for SSH key management:
    - Get-SSHKeys (ssh-list): list loaded keys
    - Add-SSHKeyIfNotLoaded (ssh-add-if): idempotent key loader
    - Start-SSHAgent (ssh-agent-start): start agent if not running
#>
if (-not (Test-Path Function:\Get-SSHKeys)) {
    New-Item -Path Function:\Get-SSHKeys -Value { ssh-add -l } -Force | Out-Null
}
if (-not (Test-Path Function:\Start-SSHAgent)) {
    New-Item -Path Function:\Start-SSHAgent -Value { $null } -Force | Out-Null
}
'@
            Set-Content -Path $testFile -Value $testContent -Encoding UTF8

            $parsed = Get-DocumentedCommands -ProfilePath $testProfileDir
            $keys = $parsed.Functions | Where-Object { $_.Name -eq 'Get-SSHKeys' } | Select-Object -First 1
            $agent = $parsed.Functions | Where-Object { $_.Name -eq 'Start-SSHAgent' } | Select-Object -First 1

            $keys | Should -Not -BeNullOrEmpty
            $keys.Synopsis | Should -Match 'list loaded keys'
            $agent | Should -Not -BeNullOrEmpty
            $agent.Synopsis | Should -Match 'start agent'
        }

        It 'resolves help from unstructured file-level comments mentioning the function' {
            $docsModulesPath = Join-Path $script:ScriptsUtilsDocsPath 'modules'
            Import-Module (Join-Path $docsModulesPath 'DocParser.psm1') -DisableNameChecking -Force

            $testProfileDir = Join-Path $script:TestTempRoot 'file_level_unstructured_profile'
            New-Item -ItemType Directory -Path $testProfileDir -Force | Out-Null
            $testFile = Join-Path $testProfileDir 'scoop.ps1'
            $testContent = @'
<#
Idempotent lazy-loading setup for Scoop tab completion.
Creates an Enable-ScoopCompletion function that can be called on-demand to enable completion.
#>
if (-not (Test-Path Function:\Enable-ScoopCompletion)) {
    New-Item -Path Function:\Enable-ScoopCompletion -Value { $null } -Force | Out-Null
}
'@
            Set-Content -Path $testFile -Value $testContent -Encoding UTF8

            $parsed = Get-DocumentedCommands -ProfilePath $testProfileDir
            $function = $parsed.Functions | Where-Object { $_.Name -eq 'Enable-ScoopCompletion' } | Select-Object -First 1

            $function | Should -Not -BeNullOrEmpty
            $function.Synopsis | Should -Match 'on-demand'
            $function.Description | Should -Match 'on-demand'
        }

        It 'promotes synopsis to description for single-line dynamic registrations' {
            $docsModulesPath = Join-Path $script:ScriptsUtilsDocsPath 'modules'
            Import-Module (Join-Path $docsModulesPath 'DocParser.psm1') -DisableNameChecking -Force

            $testFile = Join-Path $script:TestTempRoot 'synopsis_promotion.ps1'
            $testContent = @'
# Git clone - clone a repository
Register-LazyFunction -Name 'Invoke-GitClone' -Initializer { $null } -Alias 'gcl'
'@
            Set-Content -Path $testFile -Value $testContent -Encoding UTF8

            $parsed = Get-DocumentedCommands -ProfilePath (Split-Path -Parent $testFile)
            $function = $parsed.Functions | Where-Object { $_.Name -eq 'Invoke-GitClone' } | Select-Object -First 1

            $function.Description | Should -Match 'Git clone'
        }

        It 'reuses pre-parsed content and ast when supplied to dynamic parsers' {
            $docsModulesPath = Join-Path $script:ScriptsUtilsDocsPath 'modules'
            Import-Module (Join-Path $docsModulesPath 'DocAgentModeFunctionParser.psm1') -DisableNameChecking -Force
            Import-Module (Join-Path $docsModulesPath 'DocAliasParser.psm1') -DisableNameChecking -Force

            $testFile = Join-Path $script:TestTempRoot 'parser_reuse.ps1'
            $testContent = @'
# Git clone - clone a repository
Register-LazyFunction -Name 'Invoke-GitClone' -Initializer { $null } -Alias 'gcl'
'@
            Set-Content -Path $testFile -Value $testContent -Encoding UTF8

            $content = Get-Content -LiteralPath $testFile -Raw
            $fileLines = [string[]]@($content -split "\r?\n")
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($testFile, [ref]$null, [ref]$null)

            $dynamic = Parse-DynamicFunctionsFromFile -File $testFile -Content $content -FileLines $fileLines -Ast $ast
            $aliases = Parse-AliasesFromFile -File $testFile -Functions $dynamic -Content $content -Ast $ast

            ($dynamic | Where-Object { $_.Name -eq 'Invoke-GitClone' }).Count | Should -Be 1
            ($aliases | Where-Object { $_.Name -eq 'gcl' }).Count | Should -Be 1
        }

        It 'binds help content from real profile files without parameter errors' {
            $docsModulesPath = Join-Path $script:ScriptsUtilsDocsPath 'modules'
            Import-Module (Join-Path $docsModulesPath 'DocAliasParser.psm1') -DisableNameChecking -Force
            Import-Module (Join-Path $docsModulesPath 'DocHelpParser.psm1') -DisableNameChecking -Force

            $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            $file = Join-Path $repoRoot 'profile.d/git-modules/core/git-advanced.ps1'
            $fileLines = [string[]]@(Get-Content -LiteralPath $file)
            $content = $fileLines -join "`n"
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
            $cmd = $ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -ieq 'Register-LazyFunction'
                }, $true) | Where-Object {
                    (Get-CommandParameterValue -CommandAst $_ -ParameterName 'Name') -eq 'Invoke-GitClone'
                } | Select-Object -First 1

            { Get-RegistrationHelpContent -FileContent $content -SourceFileLines $fileLines -RegistrationCommandAst $cmd -FunctionName 'Invoke-GitClone' } |
                Should -Not -Throw
        }

        It 'uses single-line caption comments above block help when both are present' {
            $docsModulesPath = Join-Path $script:ScriptsUtilsDocsPath 'modules'
            Import-Module (Join-Path $docsModulesPath 'DocParser.psm1') -DisableNameChecking -Force

            $testFile = Join-Path $script:TestTempRoot 'caption_and_block_help.ps1'
            $testContent = @'
# Git log - show commit log
<#
.SYNOPSIS
    Shows commit history.
.DESCRIPTION
    Displays the commit log for the repository.
#>
Set-AgentModeFunction -Name 'Get-GitLog' -Body { git log @args } | Out-Null
'@
            Set-Content -Path $testFile -Value $testContent -Encoding UTF8

            $parsed = Get-DocumentedCommands -ProfilePath (Split-Path -Parent $testFile)
            $function = $parsed.Functions | Where-Object { $_.Name -eq 'Get-GitLog' } | Select-Object -First 1

            $function.Synopsis | Should -Match 'Shows commit history'
            $function.Synopsis | Should -Not -Match 'Git log - show commit log'
        }
    }

    Context 'Alias parsing' {
        It 'extracts aliases from Register-LazyFunction -Alias registrations' {
            $aliasParserPath = Join-Path $script:ScriptsUtilsDocsPath 'modules' 'DocAliasParser.psm1'
            Import-Module $aliasParserPath -DisableNameChecking -Force

            $testFile = Join-Path $script:TestTempRoot 'register_lazy_alias.ps1'
            $testContent = @'
# Git clone - clone a repository
Register-LazyFunction -Name 'Invoke-GitClone' -Initializer { $null } -Alias 'gcl'
'@
            Set-Content -Path $testFile -Value $testContent -Encoding UTF8

            $aliases = Parse-AliasesFromFile -File $testFile -Functions @()
            $alias = $aliases | Where-Object { $_.Name -eq 'gcl' } | Select-Object -First 1

            $alias | Should -Not -BeNullOrEmpty
            $alias.Target | Should -Be 'Invoke-GitClone'
            ($aliases | Where-Object { $_.Name -eq 'gcl' }).Count | Should -Be 1
        }

        It 'uses target function help when aliases are grouped at end of fragment' {
            $aliasParserPath = Join-Path $script:ScriptsUtilsDocsPath 'modules' 'DocAliasParser.psm1'
            $functionParserPath = Join-Path $script:ScriptsUtilsDocsPath 'modules' 'DocFunctionParser.psm1'
            Import-Module $functionParserPath -DisableNameChecking -Force
            Import-Module $aliasParserPath -DisableNameChecking -Force

            $testFile = Join-Path $script:TestTempRoot 'grouped_aliases.ps1'
            $testContent = @'
<#
.SYNOPSIS
    Upgrades all outdated Python packages using uv.
.DESCRIPTION
    Lists all outdated packages and upgrades them to their latest versions.
#>
function Update-UVOutdatedPackages {
    [CmdletBinding()]
    param()
}

<#
.SYNOPSIS
    Syncs UV project dependencies.
.DESCRIPTION
    Installs and synchronizes all project dependencies.
#>
function Sync-UVDependencies {
    [CmdletBinding()]
    param()
}

if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'uvupgrade' -Target 'Update-UVOutdatedPackages'
    Set-AgentModeAlias -Name 'uvs' -Target 'Sync-UVDependencies'
}
'@
            Set-Content -Path $testFile -Value $testContent -Encoding UTF8

            $content = Get-Content $testFile -Raw
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($testFile, [ref]$null, [ref]$null)
            $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

            $functions = [System.Collections.Generic.List[PSCustomObject]]::new()
            foreach ($funcAst in $functionAsts) {
                $parsedFunction = Parse-FunctionDocumentation -FuncAst $funcAst -Content $content -File $testFile
                if ($parsedFunction) {
                    $functions.Add($parsedFunction)
                }
            }

            $aliases = Parse-AliasesFromFile -File $testFile -Functions $functions
            $uvupgrade = $aliases | Where-Object { $_.Name -eq 'uvupgrade' } | Select-Object -First 1
            $uvs = $aliases | Where-Object { $_.Name -eq 'uvs' } | Select-Object -First 1

            $uvupgrade | Should -Not -BeNullOrEmpty
            $uvupgrade.Synopsis | Should -Match 'outdated'
            $uvupgrade.Synopsis | Should -Not -Match 'Syncs UV'

            $uvs | Should -Not -BeNullOrEmpty
            $uvs.Synopsis | Should -Match 'Syncs UV project dependencies'
        }
    }

    Context 'File generation' {
        It 'creates markdown files in correct subdirectories' {
            $tempDir = Join-Path $script:TestTempRoot 'docs_test'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            $testProfileDir = Join-Path $tempDir 'profile.d'
            New-Item -ItemType Directory -Path $testProfileDir -Force | Out-Null

            $testFunction = @'
<#
.SYNOPSIS
    Test function
.DESCRIPTION
    Test description
.PARAMETER Name
    The name parameter
.EXAMPLE
    Test-Function -Name "test"
#>
function Test-Function {
    param($Name)
}
'@

            $testFile = Join-Path $testProfileDir 'test.ps1'
            Set-Content -Path $testFile -Value $testFunction -Encoding UTF8

            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            $outputPath = Join-Path $tempDir 'api'
            & $scriptPath -OutputPath $outputPath -ProfilePath $testProfileDir 2>&1 | Out-Null

            # Verify subdirectories were created
            $functionsPath = Join-Path $outputPath 'functions'
            $aliasesPath = Join-Path $outputPath 'aliases'
            Test-Path $functionsPath | Should -Be $true
            Test-Path $aliasesPath | Should -Be $true
        }

        It 'generates function documentation in functions subdirectory' {
            $tempDir = Join-Path $script:TestTempRoot 'docs_functions'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            $testProfileDir = Join-Path $tempDir 'profile.d'
            New-Item -ItemType Directory -Path $testProfileDir -Force | Out-Null

            $testFunction = @'
<#
.SYNOPSIS
    Test function for documentation
.DESCRIPTION
    This function tests documentation generation
#>
function Test-DocumentationFunction {
    param()
}
'@

            $testFile = Join-Path $testProfileDir 'test.ps1'
            Set-Content -Path $testFile -Value $testFunction -Encoding UTF8

            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            $outputPath = Join-Path $tempDir 'api'
            & $scriptPath -OutputPath $outputPath -ProfilePath $testProfileDir 2>&1 | Out-Null

            $functionDocPath = Join-Path $outputPath 'functions' 'Test-DocumentationFunction.md'
            Test-Path $functionDocPath | Should -Be $true

            if (Test-Path $functionDocPath) {
                $content = Get-Content $functionDocPath -Raw
                $content | Should -Match 'Test-DocumentationFunction'
                $content | Should -Match 'Test function for documentation'
            }
        }

        It 'generates alias documentation in aliases subdirectory' {
            $tempDir = Join-Path $script:TestTempRoot 'docs_aliases'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            $testProfileDir = Join-Path $tempDir 'profile.d'
            New-Item -ItemType Directory -Path $testProfileDir -Force | Out-Null

            $testFileContent = @'
<#
.SYNOPSIS
    Test function
.DESCRIPTION
    A test function
#>
function Test-TargetFunction {
    param()
}

Set-Alias -Name test-alias -Value Test-TargetFunction
'@

            $testFile = Join-Path $testProfileDir 'test.ps1'
            Set-Content -Path $testFile -Value $testFileContent -Encoding UTF8

            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            $outputPath = Join-Path $tempDir 'api'
            & $scriptPath -OutputPath $outputPath -ProfilePath $testProfileDir 2>&1 | Out-Null

            $aliasDocPath = Join-Path $outputPath 'aliases' 'test-alias.md'
            if (Test-Path $aliasDocPath) {
                $content = Get-Content $aliasDocPath -Raw
                $content | Should -Match 'test-alias'
                $content | Should -Match 'Test-TargetFunction'
            }
        }

        It 'generates index with functions and aliases sections' {
            $tempDir = Join-Path $script:TestTempRoot 'docs_index'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            $testProfileDir = Join-Path $tempDir 'profile.d'
            New-Item -ItemType Directory -Path $testProfileDir -Force | Out-Null
            $testFileContent = @'
<#
.SYNOPSIS
    Sample function.
.DESCRIPTION
    Used for index generation tests.
#>
function Test-IndexFunction { }

Set-Alias -Name test-index-alias -Value Test-IndexFunction
'@
            Set-Content -Path (Join-Path $testProfileDir 'test.ps1') -Value $testFileContent -Encoding UTF8

            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            $outputPath = Join-Path $tempDir 'api'
            & $scriptPath -OutputPath $outputPath -ProfilePath $testProfileDir 2>&1 | Out-Null

            $readmePath = Join-Path $outputPath 'README.md'
            if (Test-Path $readmePath) {
                $content = Get-Content $readmePath -Raw
                # Check for new structure
                $content | Should -Match '## Functions'
                $content | Should -Match '## Aliases'
                # Check for links to subdirectories
                $content | Should -Match 'functions/'
                $content | Should -Match 'aliases/'
            }
        }

        It 'creates functions and aliases subdirectories' {
            $tempDir = Join-Path $script:TestTempRoot 'docs_structure'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            $testProfileDir = Join-Path $tempDir 'profile.d'
            New-Item -ItemType Directory -Path $testProfileDir -Force | Out-Null
            $testFileContent = @'
<#
.SYNOPSIS
    Sample function.
#>
function Test-StructureFunction { }
'@
            Set-Content -Path (Join-Path $testProfileDir 'test.ps1') -Value $testFileContent -Encoding UTF8

            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            $outputPath = Join-Path $tempDir 'api'
            & $scriptPath -OutputPath $outputPath -ProfilePath $testProfileDir 2>&1 | Out-Null

            # Verify directory structure
            $functionsPath = Join-Path $outputPath 'functions'
            $aliasesPath = Join-Path $outputPath 'aliases'

            Test-Path $functionsPath | Should -Be $true -Because 'functions subdirectory should exist'
            Test-Path $aliasesPath | Should -Be $true -Because 'aliases subdirectory should exist'

            # Verify they are directories
            (Get-Item $functionsPath).PSIsContainer | Should -Be $true
            (Get-Item $aliasesPath).PSIsContainer | Should -Be $true
        }
    }
}
