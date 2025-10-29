# ===============================================
# 16-clipboard.ps1
# Clipboard helpers (cross-platform via pwsh)
# ===============================================

# Copy text to clipboard (uses Set-Clipboard when available)
if (-not (Test-Path Function:cb -ErrorAction SilentlyContinue)) {
    <#
    .SYNOPSIS
        Copies input to the clipboard.

    .DESCRIPTION
        Copies text or objects to the clipboard. Uses Set-Clipboard if available,
        otherwise falls back to the 'clip' command.
    #>
    function cb {
        [CmdletBinding()] param([Parameter(ValueFromPipeline = $true)] $input)
        process {
            if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
                if (Test-CachedCommand Set-Clipboard) { $input | Set-Clipboard } else { $input | Out-String | clip }
            }
            else {
                if ($null -ne (Get-Command -Name Set-Clipboard -ErrorAction SilentlyContinue)) { $input | Set-Clipboard } else { $input | Out-String | clip }
            }
        }
    }
}

# Paste from clipboard
if (-not (Test-Path Function:pb -ErrorAction SilentlyContinue)) {
    <#
    .SYNOPSIS
        Pastes content from the clipboard.

    .DESCRIPTION
        Retrieves content from the clipboard. Uses Get-Clipboard if available,
        otherwise falls back to the 'paste' command.
    #>
    function pb {
        if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
            if (Test-CachedCommand Get-Clipboard) { Get-Clipboard } else { cmd /c paste }
        }
        else {
            if ($null -ne (Get-Command -Name Get-Clipboard -ErrorAction SilentlyContinue)) { Get-Clipboard } else { cmd /c paste }
        }
    }
}

























