# ===============================================
# clipboard.ps1
# Clipboard helpers (cross-platform)
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

if (-not (Test-Path Function:Copy-ToClipboard -ErrorAction SilentlyContinue)) {
    <#
    .SYNOPSIS
        Copies input to the clipboard.

    .DESCRIPTION
        Copies text or objects to the clipboard. Uses Set-Clipboard on Windows/pwsh,
        wl-copy (Wayland), xclip/xsel (X11), or pbcopy (macOS) as available.

    .PARAMETER InputObject
        The object(s) to copy. Accepts pipeline input.

    .EXAMPLE
        "hello" | Copy-ToClipboard

    .EXAMPLE
        Get-Content file.txt | Copy-ToClipboard
    #>
    function Copy-ToClipboard {
        [CmdletBinding()]
        param([Parameter(ValueFromPipeline = $true)] $InputObject)
        process {
            try {
                if (Test-CachedCommand Set-Clipboard) {
                    $InputObject | Set-Clipboard
                }
                elseif ($IsLinux) {
                    $text = $InputObject | Out-String
                    if (Test-CachedCommand wl-copy) {
                        $text | wl-copy
                    }
                    elseif (Test-CachedCommand xclip) {
                        $text | xclip -selection clipboard
                    }
                    elseif (Test-CachedCommand xsel) {
                        $text | xsel --clipboard --input
                    }
                    else {
                        Write-Warning "No clipboard tool found. Install wl-clipboard (Wayland) or xclip/xsel (X11)."
                    }
                }
                elseif ($IsMacOS -and (Test-CachedCommand pbcopy)) {
                    $InputObject | Out-String | pbcopy
                }
                elseif (Test-CachedCommand clip) {
                    $InputObject | Out-String | clip
                }
                else {
                    Write-Warning "No clipboard tool available on this platform."
                }
            }
            catch {
                Write-Warning "Failed to copy to clipboard: $_"
            }
        }
    }
    Set-AgentModeAlias -Name 'cb' -Target 'Copy-ToClipboard'
}

if (-not (Test-Path Function:Get-FromClipboard -ErrorAction SilentlyContinue)) {
    <#
.SYNOPSIS
        Pastes content from the clipboard.


    .DESCRIPTION
        Retrieves content from the clipboard. Uses Get-Clipboard on Windows/pwsh,
        wl-paste (Wayland), xclip/xsel (X11), or pbpaste (macOS) as available.


    .OUTPUTS
        System.String

    .EXAMPLE
    Get-FromClipboard
#>
    function Get-FromClipboard {
        try {
            if (Test-CachedCommand Get-Clipboard) {
                Get-Clipboard
            }
            elseif ($IsLinux) {
                if (Test-CachedCommand wl-paste) {
                    wl-paste
                }
                elseif (Test-CachedCommand xclip) {
                    xclip -selection clipboard -out
                }
                elseif (Test-CachedCommand xsel) {
                    xsel --clipboard --output
                }
                else {
                    Write-Warning "No clipboard tool found. Install wl-clipboard (Wayland) or xclip/xsel (X11)."
                    $null
                }
            }
            elseif ($IsMacOS -and (Test-CachedCommand pbpaste)) {
                pbpaste
            }
            else {
                Write-Warning "No clipboard tool available on this platform."
                $null
            }
        }
        catch {
            Write-Warning "Failed to paste from clipboard: $_"
            $null
        }
    }
    Set-AgentModeAlias -Name 'pb' -Target 'Get-FromClipboard'
}
