<#
scripts/utils/docs/modules/DocCleanup.psm1

.SYNOPSIS
    Documentation cleanup utilities.

.DESCRIPTION
    Provides functions for cleaning up stale documentation files.
#>

$docPathsModule = Join-Path $PSScriptRoot 'DocPaths.psm1'
if (Test-Path $docPathsModule) {
    Import-Module $docPathsModule -DisableNameChecking -Force -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Removes stale documentation files.

.DESCRIPTION
    Scans the documentation directory and removes markdown files that don't correspond
    to any documented commands.

.PARAMETER DocsPath
    Path to the documentation directory.

.PARAMETER DocumentedCommandNames
    List of command names that should have documentation files.

.OUTPUTS
    None. Files are removed directly.
.EXAMPLE
    Remove-StaleDocumentation

#>
function Remove-StaleDocumentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DocsPath,

        [Parameter(Mandatory)]
        [System.Collections.Generic.List[string]]$DocumentedCommandNames
    )

    Write-ScriptMessage -Message "`nCleaning up stale documentation..."
    $allDocFiles = @(Get-ChildItem -Path $DocsPath -Filter '*.md' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'README.md' })
    $documentedBaseNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($commandName in $DocumentedCommandNames) {
        $fileName = Get-DocumentationMarkdownFileName -CommandName $commandName
        [void]$documentedBaseNames.Add([System.IO.Path]::GetFileNameWithoutExtension($fileName))
    }

    $staleDocs = $allDocFiles | Where-Object { -not $documentedBaseNames.Contains($_.BaseName) }

    if ($staleDocs.Count -gt 0) {
        Write-ScriptMessage -Message "Removing $($staleDocs.Count) stale documentation file(s):"
        foreach ($staleDoc in $staleDocs) {
            Write-ScriptMessage -Message "  - Removing $($staleDoc.Name)"
            Remove-Item -Path $staleDoc.FullName -Force
        }
    }
    else {
        Write-ScriptMessage -Message "No stale documentation files found."
    }

    for ($dotCount = 2; $dotCount -le 8; $dotCount++) {
        $legacyPath = Join-Path $DocsPath (('.' * $dotCount) + '.md')
        $encodedPath = Join-Path $DocsPath "dot$dotCount.md"
        if ((Test-Path -LiteralPath $legacyPath) -and (Test-Path -LiteralPath $encodedPath)) {
            Write-ScriptMessage -Message "  - Removing legacy dot collision file: $(Split-Path -Leaf $legacyPath)"
            Remove-Item -LiteralPath $legacyPath -Force
        }
    }
}

Export-ModuleMember -Function Remove-StaleDocumentation

