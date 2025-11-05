# ===============================================
# 16-clipboard.ps1
# Clipboard helpers (cross-platform via pwsh)
# ===============================================

# Copy text to clipboard (uses Set-Clipboard when available)
if (-not (Test-Path Function:Copy-ToClipboard -ErrorAction SilentlyContinue)) {
    <#
    .SYNOPSIS
        Copies input to the clipboard.

    .DESCRIPTION
        Copies text or objects to the clipboard. Uses Set-Clipboard if available,
        otherwise falls back to the 'clip' command.
    #>
    function Copy-ToClipboard {
        [CmdletBinding()] param([Parameter(ValueFromPipeline = $true)] $input)
        process {
            try {
                # Use Test-HasCommand which handles caching and fallback internally
                if (Test-HasCommand Set-Clipboard) { $input | Set-Clipboard } else { $input | Out-String | clip }
            }
            catch {
                Write-Warning "Failed to copy to clipboard: $_"
            }
        }
    }
    Set-Alias -Name cb -Value Copy-ToClipboard -ErrorAction SilentlyContinue
}

# Paste from clipboard
if (-not (Test-Path Function:Get-FromClipboard -ErrorAction SilentlyContinue)) {
    <#
    .SYNOPSIS
        Pastes content from the clipboard.

    .DESCRIPTION
        Retrieves content from the clipboard. Uses Get-Clipboard if available,
        otherwise falls back to the 'paste' command.
    #>
    function Get-FromClipboard {
        try {
            # Use Test-HasCommand which handles caching and fallback internally
            if (Test-HasCommand Get-Clipboard) { Get-Clipboard } else { cmd /c paste }
        }
        catch {
            Write-Warning "Failed to paste from clipboard: $_"
            $null
        }
    }
    Set-Alias -Name pb -Value Get-FromClipboard -ErrorAction SilentlyContinue
}
