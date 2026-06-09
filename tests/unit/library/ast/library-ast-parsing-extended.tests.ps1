<#
tests/unit/library-ast-parsing-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for AstParsing help-adjacent extraction helpers.
#>

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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'file' 'FileContent.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $script:LibPath 'code-analysis' 'AstParsing.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'AstParsingExtended'
    $script:HelpScript = Join-Path $script:TempDir 'help-before.ps1'
    @'
<#
.SYNOPSIS
    Documented function.
#>
function Get-Documented {
    return 'ok'
}
'@ | Set-Content -LiteralPath $script:HelpScript -Encoding UTF8
}

AfterAll {
    Remove-Module AstParsing, FileContent -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'AstParsing extended scenarios' {
    Context 'Get-TextBeforeFunction' {
        It 'Includes comment-based help that precedes the function' {
            $ast = Get-PowerShellAst -Path $script:HelpScript
            $func = @(Get-FunctionsFromAst -Ast $ast)[0]
            $content = Get-Content -LiteralPath $script:HelpScript -Raw

            $beforeText = Get-TextBeforeFunction -FuncAst $func -Content $content

            $beforeText | Should -Match '\.SYNOPSIS'
            $beforeText | Should -Match 'Documented function'
        }
    }

    Context 'Get-FunctionSignature' {
        It 'Includes cmdlet binding attributes in signatures' {
            $scriptPath = Join-Path $script:TempDir 'advanced.ps1'
            @'
function Invoke-Advanced {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
}
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

            $ast = Get-PowerShellAst -Path $scriptPath
            $func = @(Get-FunctionsFromAst -Ast $ast)[0]
            $signature = Get-FunctionSignature -FuncAst $func

            $signature | Should -Match 'Invoke-Advanced'
            $signature | Should -Match 'Name'
        }
    }

    Context 'Get-FunctionsFromAst' {
        It 'Finds filter functions when IncludeInternal is specified' {
            $scriptPath = Join-Path $script:TempDir 'filter.ps1'
            @'
filter global:Test-Filter {
    $_ -like 'a*'
}
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

            $ast = Get-PowerShellAst -Path $scriptPath
            $functions = @(Get-FunctionsFromAst -Ast $ast -IncludeInternal)
            @($functions | ForEach-Object { $_.Name }) | Should -Contain 'global:Test-Filter'
        }

        It 'Returns an empty collection for scripts without functions' {
            $scriptPath = Join-Path $script:TempDir 'empty-functions.ps1'
            Set-Content -LiteralPath $scriptPath -Value 'Write-Output 1' -Encoding UTF8

            $ast = Get-PowerShellAst -Path $scriptPath
            $functions = @(Get-FunctionsFromAst -Ast $ast)

            $functions.Count | Should -Be 0
        }
    }

    Context 'Get-FunctionBody' {
        It 'Returns function body text from the AST extent' {
            $ast = Get-PowerShellAst -Path $script:HelpScript
            $func = @(Get-FunctionsFromAst -Ast $ast)[0]

            $body = Get-FunctionBody -FuncAst $func

            $body | Should -Match "return 'ok'"
        }

    }

    Context 'Get-AstComplexity' {
        It 'Counts control-flow statements in a script AST' {
            $scriptPath = Join-Path $script:TempDir 'complexity.ps1'
            @'
if ($true) { Write-Output 1 }
foreach ($item in 1..2) { if ($item -eq 1) { Write-Output $item } }
try { Write-Output 3 } catch { Write-Output 4 }
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

            $ast = Get-PowerShellAst -Path $scriptPath
            $complexity = Get-AstComplexity -Ast $ast

            $complexity | Should -BeGreaterThan 2
        }
    }

    Context 'AstParsing test environment hooks' {
        It 'Throws for missing files when Validation is available' {
            Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
            $missing = Join-Path $script:TempDir 'validation-missing.ps1'

            { Get-PowerShellAst -Path $missing } | Should -Throw '*not found*'
        }

        It 'Falls back to Get-Content when Read-FileContent throws' {
            $scriptPath = Join-Path $script:TempDir 'fallback-read.ps1'
            Set-Content -LiteralPath $scriptPath -Value 'function Get-Fallback { 1 }' -Encoding UTF8

            function global:Read-FileContent {
                param([string]$Path)
                throw 'ast parsing read fallback probe'
            }

            try {
                $ast = Get-PowerShellAst -Path $scriptPath
                $ast | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Item -Path Function:Read-FileContent -ErrorAction SilentlyContinue -Force
                Import-Module (Join-Path $script:LibPath 'file' 'FileContent.psm1') -DisableNameChecking -Force
            }
        }

        It 'Summarizes syntax errors with truncated and counted messages' {
            $scriptPath = Join-Path $script:TempDir 'syntax-errors.ps1'
            @'
function Broken-One {
function Broken-Two {
function Broken-Three {
function Broken-Four {
function Broken-Five {
function Broken-Six {
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

            { Get-PowerShellAst -Path $scriptPath } | Should -Throw '*syntax errors*'
        }

        It 'Includes typed parameter names in function signatures' {
            $scriptPath = Join-Path $script:TempDir 'typed-params.ps1'
            @'
function Get-TypedValue {
    param(
        [int]$Count,
        [string]$Name
    )
}
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

            $ast = Get-PowerShellAst -Path $scriptPath
            $func = @(Get-FunctionsFromAst -Ast $ast)[0]
            $signature = Get-FunctionSignature -FuncAst $func

            $signature | Should -Match '\[Int32\]\$Count'
            $signature | Should -Match '\[String\]\$Name'
        }

        It 'Uses manual validation when PS_PROFILE_AST_PARSING_SKIP_VALIDATION is enabled' {
            $missing = Join-Path $script:TempDir 'manual-validation-missing.ps1'
            $originalFlag = $env:PS_PROFILE_AST_PARSING_SKIP_VALIDATION
            $env:PS_PROFILE_AST_PARSING_SKIP_VALIDATION = '1'

            try {
                { Get-PowerShellAst -Path $missing } | Should -Throw '*not found*'
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_AST_PARSING_SKIP_VALIDATION -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_AST_PARSING_SKIP_VALIDATION = $originalFlag
                }
            }
        }
    }
}
