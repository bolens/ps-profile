# ===============================================
# File listing utility functions
# Directory listing with eza support
# ===============================================

# Lazy bulk initializer for file listing helpers
<#
.SYNOPSIS
    Initializes file listing utility functions on first use.
.DESCRIPTION
    Sets up all file listing utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
#>
if (-not (Test-Path "Function:\\Ensure-FileListing")) {
    function Ensure-FileListing {
        # Listing helpers (prefer eza when available)
        Set-Item -Path Function:global:Get-ChildItemDetailed -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-CachedCommand eza) { eza -la --icons --git @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Alias -Name ll -Value Get-ChildItemDetailed -Scope Global -ErrorAction SilentlyContinue
        Set-Item -Path Function:global:Get-ChildItemAll -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-CachedCommand eza) { eza -la --icons @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Alias -Name la -Value Get-ChildItemAll -Scope Global -ErrorAction SilentlyContinue
        Set-Item -Path Function:global:Get-ChildItemVisible -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-CachedCommand eza) { eza --icons @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Alias -Name lx -Value Get-ChildItemVisible -Scope Global -ErrorAction SilentlyContinue
        Set-Item -Path Function:global:Get-DirectoryTree -Value { 
            param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) 
            if (Test-CachedCommand eza) { 
                try {
                    eza -T --icons @fileArgs
                }
                catch {
                    Write-Warning "eza command failed: $($_.Exception.Message). Falling back to Get-ChildItem."
                    try {
                        Get-ChildItem -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer } | Select-Object FullName
                    }
                    catch {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'files.listing.directory-tree' -Context @{
                                tool     = 'eza'
                                fallback = $true
                            }
                        }
                        else {
                            Write-Error "Failed to get directory tree: $($_.Exception.Message)"
                        }
                    }
                }
            } 
            else { 
                if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                    Invoke-WithWideEvent -OperationName 'files.listing.directory-tree' -Context @{
                        tool = 'Get-ChildItem'
                    } -ScriptBlock {
                        Get-ChildItem -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer } | Select-Object FullName
                    } | Out-Null
                }
                else {
                    try {
                        Get-ChildItem -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer } | Select-Object FullName
                    }
                    catch {
                        Write-Error "Failed to get directory tree: $($_.Exception.Message)"
                    }
                }
            } 
        } -Force | Out-Null
        Set-Alias -Name tree -Value Get-DirectoryTree -Scope Global -ErrorAction SilentlyContinue

        # bat wrapper
        Set-Item -Path Function:global:Show-FileContent -Value {
            param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
            $batCommand = Get-Command bat -CommandType Application -ErrorAction SilentlyContinue
            if ($fileArgs) {
                if ($batCommand) {
                    & $batCommand @fileArgs
                }
                else {
                    Get-Content -LiteralPath @fileArgs | Out-Host
                }
            }
            else {
                if ($batCommand) {
                    & $batCommand
                }
                else {
                    $input | Out-Host
                }
            }
        } -Force | Out-Null
        Set-Alias -Name bat-cat -Value Show-FileContent -Scope Global -ErrorAction SilentlyContinue
    }
}

# Initialize the functions
Ensure-FileListing

