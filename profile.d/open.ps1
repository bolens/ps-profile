# ===============================================
# open.ps1
# Cross-platform 'open' helper
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

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
        
        if (-not $p) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.ArgumentException]::new("No path or URL provided to open"),
                        'NoPathProvided',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $null
                    )) -OperationName 'open.item' -Context @{}
            }
            else {
                Write-Error "No path or URL provided to open"
            }
            return
        }
        
        # Validate path exists for file paths (not URLs)
        if ($p -notmatch '^https?://' -and $p -notmatch '^[a-zA-Z]:') {
            # Might be a relative path, try to resolve it
            try {
                if ($p -and -not [string]::IsNullOrWhiteSpace($p) -and (Test-Path -LiteralPath $p -ErrorAction SilentlyContinue)) {
                    $p = Resolve-Path $p -ErrorAction Stop | Select-Object -ExpandProperty Path
                }
            }
            catch {
                # Path doesn't exist, but might be a URL or command - continue
            }
        }
        
        try {
            if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
                # Validate file exists for local file paths
                if ($p -and -not [string]::IsNullOrWhiteSpace($p) -and $p -notmatch '^https?://' -and (Test-Path -LiteralPath $p -ErrorAction SilentlyContinue)) {
                    $fileInfo = Get-Item $p -ErrorAction Stop
                    if ($fileInfo -is [System.IO.DirectoryInfo]) {
                        # For directories, use explorer
                        Start-Process explorer.exe -ArgumentList $p -ErrorAction Stop
                    }
                    else {
                        Start-Process -FilePath $p -ErrorAction Stop
                    }
                }
                else {
                    # URL or non-existent path - try to open anyway
                    Start-Process -FilePath $p -ErrorAction Stop
                }
            }
            else {
                if (Test-CachedCommand xdg-open) {
                    & xdg-open $p 2>&1 | Out-Null
                    if ($LASTEXITCODE -ne 0) {
                        throw "xdg-open failed with exit code $LASTEXITCODE"
                    }
                }
                elseif (Test-CachedCommand open) {
                    & open $p 2>&1 | Out-Null
                    if ($LASTEXITCODE -ne 0) {
                        throw "open command failed with exit code $LASTEXITCODE"
                    }
                }
                else {
                    throw "No opener found for $p. Install xdg-open (Linux) or use 'open' (macOS)."
                }
            }
        }
        catch [System.ComponentModel.Win32Exception] {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'open.item' -Context @{
                    path       = $p
                    error_type = 'Win32Exception'
                }
            }
            else {
                Write-Error "Failed to open '$p': The system cannot find the file or application. $($_.Exception.Message)"
            }
            throw
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'open.item' -Context @{
                    path       = $p
                    error_type = 'ItemNotFoundException'
                }
            }
            else {
                Write-Error "Failed to open '$p': File or path not found. $($_.Exception.Message)"
            }
            throw
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'open.item' -Context @{
                    path = $p
                }
            }
            else {
                Write-Error "Failed to open '$p': $($_.Exception.Message)"
            }
            throw
        }
    }
    Set-Alias -Name open -Value Open-Item -ErrorAction SilentlyContinue
}
