<#
scripts/utils/docs/modules/FragmentReadmeGenerator.psm1

.SYNOPSIS
    Fragment README markdown generation utilities.

.DESCRIPTION
    Provides functions for generating markdown content for fragment README files.
#>

<#
.SYNOPSIS
    Generates markdown content for a fragment README.

.DESCRIPTION
    Creates markdown content including purpose, usage, functions, enable helpers, dependencies, and notes.

.PARAMETER FileName
    Name of the fragment file.

.PARAMETER Purpose
    Purpose statement extracted from the fragment.

.PARAMETER Functions
    List of functions with their descriptions.

.PARAMETER EnableHelpers
    Array of Enable-* helper function names.

.OUTPUTS
    String. Complete markdown content for the README.
#>
function New-FragmentReadmeContent {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$FileName,

        [Parameter(Mandatory)]
        [string]$Purpose,

        [Parameter(Mandatory)]
        [System.Collections.Generic.List[PSCustomObject]]$Functions,

        [Parameter(Mandatory)]
        [string[]]$EnableHelpers
    )

    $title = "profile.d/$FileName"
    $underline = '=' * $title.Length

    $md = @()
    $md += $title
    $md += $underline
    $md += ''
    $md += 'Purpose'
    $md += '-------'
    $md += $Purpose
    $md += ''
    $md += 'Usage'
    $md += '-----'
    $md += ('See the fragment source: `{0}` for examples and usage notes.' -f $FileName)

    if ($Functions.Count -gt 0) {
        $md += ''
        $md += 'Functions'
        $md += '---------'
        foreach ($f in $Functions) {
            if ($f.Short) {
                $md += ('- `{0}` — {1}' -f $f.Name, $f.Short)
            }
            else {
                $md += ('- `{0}`' -f $f.Name)
            }
        }
    }

    if ($EnableHelpers.Count -gt 0) {
        $md += ''
        $md += 'Enable helpers'
        $md += '--------------'
        foreach ($h in $EnableHelpers) {
            $md += ('- {0} (lazy enabler; imports or config when called)' -f $h)
        }
    }

    $md += ''
    $md += 'Dependencies'
    $md += '------------'
    $md += 'None explicit; see the fragment for runtime checks and optional tooling dependencies.'
    $md += ''
    $md += 'Notes'
    $md += '-----'
    $md += 'Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.'

    return $md -join [Environment]::NewLine
}

Export-ModuleMember -Function New-FragmentReadmeContent

