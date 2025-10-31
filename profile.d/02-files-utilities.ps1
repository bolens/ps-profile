# ===============================================
# 02-files-utilities.ps1
# File utility functions
# ===============================================

# Lazy bulk initializer for file utility helpers
<#
.SYNOPSIS
    Initializes file utility functions on first use.
.DESCRIPTION
    Sets up all file utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
#>
if (-not (Test-Path "Function:\\Ensure-FileUtilities")) {
    function Ensure-FileUtilities {
        # head (first N lines))
        Set-Item -Path Function:head -Value {
            param([Parameter(ValueFromPipeline = $true)] $InputObject, [int]$Lines = 10, [Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
            process {
                if ($InputObject) { $InputObject | Select-Object -First $Lines }
                elseif ($fileArgs) { Get-Content -LiteralPath @fileArgs | Select-Object -First $Lines }
                else { $input | Select-Object -First $Lines }
            }
        } -Force | Out-Null

        # tail (last N lines)
        Set-Item -Path Function:tail -Value {
            param([Parameter(ValueFromPipeline = $true)] $InputObject, [int]$Lines = 10, [Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
            process {
                if ($InputObject) { $InputObject | Select-Object -Last $Lines }
                elseif ($fileArgs) { Get-Content -LiteralPath @fileArgs | Select-Object -Last $Lines }
                else { $input | Select-Object -Last $Lines }
            }
        } -Force | Out-Null

        # File hash
        Set-Item -Path Function:file-hash -Value { param([string]$Path, [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')] [string]$Algorithm = 'SHA256') if (-not (Test-Path -LiteralPath $Path)) { Write-Error "File not found: $Path"; return } Get-FileHash -Algorithm $Algorithm -Path $Path } -Force | Out-Null
        # File size
        Set-Item -Path Function:filesize -Value { param([string]$Path) if (-not (Test-Path -LiteralPath $Path)) { Write-Error "File not found: $Path"; return } $len = (Get-Item -LiteralPath $Path).Length; switch ($len) { { $_ -ge 1TB } { "{0:N2} TB" -f ($len / 1TB); break } { $_ -ge 1GB } { "{0:N2} GB" -f ($len / 1GB); break } { $_ -ge 1MB } { "{0:N2} MB" -f ($len / 1MB); break } { $_ -ge 1KB } { "{0:N2} KB" -f ($len / 1KB); break } default { "{0} bytes" -f $len } } } -Force | Out-Null

        # Hex dump
        Set-Item -Path Function:hex-dump -Value { param([string]$Path) Format-Hex -Path $Path } -Force | Out-Null
    }
}

# Head (first 10 lines) of a file
<#
.SYNOPSIS
    Shows the first N lines of a file.
.DESCRIPTION
    Displays the beginning of a file or pipeline input. Defaults to 10 lines.
.PARAMETER Lines
    The number of lines to display. Default is 10.
#>
function head { if (-not (Test-Path Function:\head)) { Ensure-FileUtilities }; return & (Get-Item Function:\head -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Tail (last 10 lines) of a file
<#
.SYNOPSIS
    Shows the last N lines of a file.
.DESCRIPTION
    Displays the end of a file or pipeline input. Defaults to 10 lines.
.PARAMETER Lines
    The number of lines to display. Default is 10.
#>
function tail { if (-not (Test-Path Function:\tail)) { Ensure-FileUtilities }; return & (Get-Item Function:\tail -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Get file hash
<#
.SYNOPSIS
    Calculates file hash using specified algorithm.
.DESCRIPTION
    Computes cryptographic hash of a file. Defaults to SHA256.
.PARAMETER Path
    The path to the file to hash.
.PARAMETER Algorithm
    The hash algorithm to use. Valid values are MD5, SHA1, SHA256, SHA384, SHA512. Default is SHA256.
#>
function file-hash { if (-not (Test-Path Function:\file-hash)) { Ensure-FileUtilities }; return & (Get-Item Function:\file-hash -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Get file size
<#
.SYNOPSIS
    Shows human-readable file size.
.DESCRIPTION
    Displays file size in appropriate units (bytes, KB, MB, GB, TB).
.PARAMETER Path
    The path to the file to check size.
#>
function filesize { if (-not (Test-Path Function:\filesize)) { Ensure-FileUtilities }; return & (Get-Item Function:\filesize -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }

# Display hex dump of file
<#
.SYNOPSIS
    Shows hex dump of a file.
.DESCRIPTION
    Displays the hexadecimal representation of a file's contents.
.PARAMETER Path
    The path to the file to dump.
#>
function hex-dump { if (-not (Test-Path Function:\hex-dump)) { Ensure-FileUtilities }; return & (Get-Item Function:\hex-dump -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args) }
