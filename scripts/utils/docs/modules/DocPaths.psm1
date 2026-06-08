<#
scripts/utils/docs/modules/DocPaths.psm1

.SYNOPSIS
    Documentation path helpers for command names with special characters.
#>

function Get-DocumentationMarkdownFileName {
    <#
    .SYNOPSIS
        Returns a safe markdown filename for a command name.

    .DESCRIPTION
        Dot-only navigation commands (.., ..., ....) would collide with the .md
        extension when interpolated as "$Name.md". This helper encodes those names
        as dot2.md, dot3.md, dot4.md, etc.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName
    )

    if ($CommandName -match '^\.+$') {
        return "dot$($CommandName.Length).md"
    }

    return "$CommandName.md"
}

function Get-DocumentationCommandNameFromMarkdownBaseName {
    <#
    .SYNOPSIS
        Resolves a markdown basename back to the original command name.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$BaseName
    )

    if ($BaseName -match '^dot(\d+)$') {
        $dotCount = [int]$matches[1]
        if ($dotCount -ge 2) {
            return '.' * $dotCount
        }
    }

    return $BaseName
}

function Get-DocumentationMarkdownRelativePath {
    <#
    .SYNOPSIS
        Returns a docs/api relative path for a command markdown file.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('functions', 'aliases')]
        [string]$Category,

        [Parameter(Mandatory)]
        [string]$CommandName
    )

    $fileName = Get-DocumentationMarkdownFileName -CommandName $CommandName
    return "$Category/$fileName"
}

Export-ModuleMember -Function @(
    'Get-DocumentationMarkdownFileName'
    'Get-DocumentationCommandNameFromMarkdownBaseName'
    'Get-DocumentationMarkdownRelativePath'
)
