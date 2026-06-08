<#
tests/unit/library-ast-parsing-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for AstParsing help-adjacent extraction helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'file' 'FileContent.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $libPath 'code-analysis' 'AstParsing.psm1') -DisableNameChecking -Force

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
}
