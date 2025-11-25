<#
scripts/utils/docs/modules/DocCleanup.psm1

.SYNOPSIS
    Documentation cleanup utilities.

.DESCRIPTION
    Provides functions for cleaning up stale documentation files.
#>

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
    $allDocFiles = Get-ChildItem -Path $DocsPath -Filter '*.md' -Exclude 'README.md' -ErrorAction SilentlyContinue
    $staleDocs = $allDocFiles | Where-Object { $_.BaseName -notin $DocumentedCommandNames }

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
}

Export-ModuleMember -Function Remove-StaleDocumentation

