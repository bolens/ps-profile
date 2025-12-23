# ===============================================
# UserHome.ps1
# User home directory resolution utility
# ===============================================

<#
.SYNOPSIS
    Resolves the current user's home directory.
.DESCRIPTION
    Returns a cross-platform home directory path by checking $env:HOME,
    $env:USERPROFILE, and finally the .NET UserProfile folder.
.OUTPUTS
    System.String
#>
function global:Get-UserHome {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $resolvedHome = $null

    if ($env:HOME) {
        $resolvedHome = $env:HOME
    }

    if (-not $resolvedHome -and $env:USERPROFILE) {
        $resolvedHome = $env:USERPROFILE
    }

    if (-not $resolvedHome) {
        try {
            $resolvedHome = [System.Environment]::GetFolderPath('UserProfile')
        }
        catch {
            $resolvedHome = $null
        }
    }

    return $resolvedHome
}

