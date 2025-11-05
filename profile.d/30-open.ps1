# ===============================================
# 30-open.ps1
# Cross-platform 'open' helper
# ===============================================

if (-not (Test-Path Function:Open-Item -ErrorAction SilentlyContinue)) {
    <#
    .SYNOPSIS
        Opens files or URLs using the system's default application.

    .DESCRIPTION
        Opens the specified file or URL using the appropriate system command.
        On Windows, uses Start-Process. On Linux/macOS, uses xdg-open or open.
    #>
    function Open-Item {
        param($p)
        if ($IsWindows) { Start-Process -FilePath $p } else {
            if (Test-HasCommand xdg-open) { xdg-open $p }
            elseif (Test-HasCommand open) { open $p }
            else { Write-Warning "No opener found for $p" }
        }
    }
    Set-Alias -Name open -Value Open-Item -ErrorAction SilentlyContinue
}
