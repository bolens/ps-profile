<#
scripts/utils/docs/modules/DocCoverage.psm1

.SYNOPSIS
    Documentation coverage reporting utilities.

.DESCRIPTION
    Compares parsed profile documentation, dynamic registrations, and generated
    markdown files to surface parser gaps, missing help, and stale artifacts.
#>

$regexModulePath = Join-Path $PSScriptRoot 'DocParserRegex.psm1'
$helpParserPath = Join-Path $PSScriptRoot 'DocHelpParser.psm1'
$functionParserPath = Join-Path $PSScriptRoot 'DocFunctionParser.psm1'
$agentModeParserPath = Join-Path $PSScriptRoot 'DocAgentModeFunctionParser.psm1'
$aliasParserPath = Join-Path $PSScriptRoot 'DocAliasParser.psm1'
$parserPath = Join-Path $PSScriptRoot 'DocParser.psm1'
$docPathsPath = Join-Path $PSScriptRoot 'DocPaths.psm1'

foreach ($modulePath in @(
        $regexModulePath
        $helpParserPath
        $functionParserPath
        $agentModeParserPath
        $aliasParserPath
        $parserPath
        $docPathsPath
    )) {
    if (Test-Path $modulePath) {
        Import-Module $modulePath -DisableNameChecking -Force -ErrorAction Stop
    }
}

function Get-DocumentationCoverageReport {
    <#
    .SYNOPSIS
        Builds a documentation coverage report for profile sources and API output.

    .DESCRIPTION
        Scans profile.d for dynamic registrations and compares parser output with
        markdown files under docs/api. Surfaces registrations without resolvable
        help, parser gaps, weak help text, and missing or orphan markdown files.

    .PARAMETER ProfilePath
        Root directory containing profile fragments.

    .PARAMETER DocsPath
        Generated API documentation root (defaults to docs/api under repo).

    .OUTPUTS
        PSCustomObject
    .EXAMPLE
        Get-DocumentationCoverageReport -ProfilePath ./profile.d -DocsPath ./docs/api
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$ProfilePath,

        [string]$DocsPath = 'docs/api'
    )

    $parsed = Get-DocumentedCommands -ProfilePath $ProfilePath
    $documentedFunctions = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $documentedAliases = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $functionByName = @{}

    foreach ($function in $parsed.Functions) {
        if ($function.Name) {
            [void]$documentedFunctions.Add($function.Name)
            $functionByName[$function.Name] = $function
        }
    }

    foreach ($alias in $parsed.Aliases) {
        if ($alias.Name) {
            [void]$documentedAliases.Add($alias.Name)
        }
    }

    $weakHelp = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($function in $parsed.Functions) {
        $synopsis = [string]$function.Synopsis
        $description = [string]$function.Description
        if ([string]::IsNullOrWhiteSpace($synopsis)) {
            $weakHelp.Add([PSCustomObject]@{
                    Name   = $function.Name
                    File   = $function.File
                    Issue  = 'EmptySynopsis'
                    Detail = $synopsis
                })
        }
        elseif ($description -match 'No description available') {
            $weakHelp.Add([PSCustomObject]@{
                    Name   = $function.Name
                    File   = $function.File
                    Issue  = 'PlaceholderDescription'
                    Detail = $synopsis
                })
        }
    }

    $registrationsWithoutHelp = [System.Collections.Generic.List[PSCustomObject]]::new()
    $parserGaps = [System.Collections.Generic.List[PSCustomObject]]::new()
    $totalDynamicRegistrations = 0
    $resolvedProfile = (Resolve-Path -LiteralPath $ProfilePath).Path

    Get-ChildItem -LiteralPath $resolvedProfile -Filter '*.ps1' -Recurse -File | ForEach-Object {
        $file = $_.FullName
        $relativeFile = $file.Substring($resolvedProfile.Length).TrimStart('\', '/')

        $content = Get-Content -LiteralPath $file -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($content)) {
            return
        }

        $parseErrors = $null
        $tokens = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$parseErrors)
        if (-not $ast) {
            return
        }

        $fileLines = [string[]]@($content -split "\r?\n")
        $registrations = Get-DynamicRegistrationCommands -Ast $ast
        foreach ($registration in $registrations) {
            $functionName = Get-RegistrationFunctionName `
                -RegistrationType $registration.Type `
                -CommandAst $registration.CommandAst `
                -PresetFunctionName $registration.FunctionName

            if (-not $functionName -or $functionName -match ':' -or $functionName -match '^__') {
                continue
            }

            $totalDynamicRegistrations++

            if ($functionName -match '^_') {
                continue
            }

            if ($documentedFunctions.Contains($functionName)) {
                continue
            }

            $helpContent = Get-RegistrationHelpContent `
                -FileContent $content `
                -SourceFileLines $fileLines `
                -RegistrationCommandAst $registration.CommandAst `
                -FunctionName $functionName

            if ($helpContent) {
                $parserGaps.Add([PSCustomObject]@{
                        Name = $functionName
                        File = $relativeFile
                    })
            }
            else {
                $registrationsWithoutHelp.Add([PSCustomObject]@{
                        Name = $functionName
                        File = $relativeFile
                    })
            }
        }
    }

    $functionsDocsPath = Join-Path $DocsPath 'functions'
    $aliasesDocsPath = Join-Path $DocsPath 'aliases'
    $markdownFunctionNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $markdownAliasNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    if (Test-Path -LiteralPath $functionsDocsPath) {
        Get-ChildItem -LiteralPath $functionsDocsPath -Filter '*.md' -File | ForEach-Object {
            $commandName = Get-DocumentationCommandNameFromMarkdownBaseName -BaseName $_.BaseName
            [void]$markdownFunctionNames.Add($commandName)
        }
    }

    if (Test-Path -LiteralPath $aliasesDocsPath) {
        Get-ChildItem -LiteralPath $aliasesDocsPath -Filter '*.md' -File | ForEach-Object {
            $commandName = Get-DocumentationCommandNameFromMarkdownBaseName -BaseName $_.BaseName
            [void]$markdownAliasNames.Add($commandName)
        }
    }

    $missingMarkdown = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($functionName in $documentedFunctions) {
        if (-not $markdownFunctionNames.Contains($functionName)) {
            $entry = $functionByName[$functionName]
            $missingMarkdown.Add([PSCustomObject]@{
                    Name = $functionName
                    Type = 'Function'
                    File = if ($entry) { $entry.File } else { $null }
                })
        }
    }

    foreach ($aliasName in $documentedAliases) {
        if (-not $markdownAliasNames.Contains($aliasName)) {
            $missingMarkdown.Add([PSCustomObject]@{
                    Name = $aliasName
                    Type = 'Alias'
                    File = $null
                })
        }
    }

    $orphanMarkdown = [System.Collections.Generic.List[PSCustomObject]]::new()
    if (Test-Path -LiteralPath $functionsDocsPath) {
        Get-ChildItem -LiteralPath $functionsDocsPath -Filter '*.md' -File | ForEach-Object {
            $commandName = Get-DocumentationCommandNameFromMarkdownBaseName -BaseName $_.BaseName
            if (-not $documentedFunctions.Contains($commandName)) {
                $orphanMarkdown.Add([PSCustomObject]@{
                        Name = $commandName
                        Type = 'Function'
                        Path = $_.FullName
                    })
            }
        }
    }

    if (Test-Path -LiteralPath $aliasesDocsPath) {
        Get-ChildItem -LiteralPath $aliasesDocsPath -Filter '*.md' -File | ForEach-Object {
            $commandName = Get-DocumentationCommandNameFromMarkdownBaseName -BaseName $_.BaseName
            if (-not $documentedAliases.Contains($commandName)) {
                $orphanMarkdown.Add([PSCustomObject]@{
                        Name = $commandName
                        Type = 'Alias'
                        Path = $_.FullName
                    })
            }
        }
    }

    return [PSCustomObject]@{
        ProfilePath                  = $resolvedProfile
        DocsPath                     = $DocsPath
        DocumentedFunctionCount      = $documentedFunctions.Count
        DocumentedAliasCount         = $documentedAliases.Count
        DynamicRegistrationCount     = $totalDynamicRegistrations
        RegistrationsWithoutHelp     = @($registrationsWithoutHelp)
        ParserGaps                   = @($parserGaps)
        WeakHelp                     = @($weakHelp)
        MissingMarkdown              = @($missingMarkdown)
        OrphanMarkdown               = @($orphanMarkdown)
    }
}

Export-ModuleMember -Function @(
    'Get-DocumentationCoverageReport'
)
