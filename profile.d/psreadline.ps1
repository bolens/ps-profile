# ===============================================
# psreadline.ps1
# PSReadLine configuration for enhanced command-line editing
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

# PSReadLine provides enhanced command-line editing experience
# This fragment configures PSReadLine if available

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'psreadline') { return }
    }

    # Check if PSReadLine module is available
    if (Get-Module -ListAvailable -Name PSReadLine -ErrorAction SilentlyContinue) {
        # Import PSReadLine if not already loaded
        if (-not (Get-Module -Name PSReadLine -ErrorAction SilentlyContinue)) {
            Import-Module PSReadLine -ErrorAction SilentlyContinue
        }

        # Configure PSReadLine options
        if (Get-Module -Name PSReadLine -ErrorAction SilentlyContinue) {
            # Set prediction source (history and/or plugin)
            Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue

            # Enable better history search
            Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward -ErrorAction SilentlyContinue
            Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward -ErrorAction SilentlyContinue

            # Enable better tab completion
            Set-PSReadLineKeyHandler -Key Tab -Function Complete -ErrorAction SilentlyContinue
            Set-PSReadLineKeyHandler -Key Ctrl+Spacebar -Function MenuComplete -ErrorAction SilentlyContinue

            # Enable better editing
            Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteChar -ErrorAction SilentlyContinue
            Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardDeleteWord -ErrorAction SilentlyContinue

            # Ensure Ctrl+C uses default CopyOrCancelLine behavior
            # (copies selected text if there's a selection, sends interrupt signal if no selection)
            Set-PSReadLineKeyHandler -Key Ctrl+c -Function CopyOrCancelLine -ErrorAction SilentlyContinue
        }
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: psreadline" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load psreadline fragment: $($_.Exception.Message)"
        }
    }
}
finally {
    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'psreadline'
    }
}
