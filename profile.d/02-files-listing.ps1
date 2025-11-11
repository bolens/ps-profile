# ===============================================
# 02-files-listing.ps1
# File listing utilities
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
        Set-Item -Path Function:global:Get-ChildItemDetailed -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-HasCommand eza) { eza -la --icons --git @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Alias -Name ll -Value Get-ChildItemDetailed -Scope Global -ErrorAction SilentlyContinue
        Set-Item -Path Function:global:Get-ChildItemAll -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-HasCommand eza) { eza -la --icons @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Alias -Name la -Value Get-ChildItemAll -Scope Global -ErrorAction SilentlyContinue
        Set-Item -Path Function:global:Get-ChildItemVisible -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-HasCommand eza) { eza --icons @fileArgs } else { Get-ChildItem -Force | Format-Table } } -Force | Out-Null
        Set-Alias -Name lx -Value Get-ChildItemVisible -Scope Global -ErrorAction SilentlyContinue
        Set-Item -Path Function:global:Get-DirectoryTree -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if (Test-HasCommand eza) { eza -T --icons @fileArgs } else { Get-ChildItem -Recurse | Where-Object { $_.PSIsContainer } | Select-Object FullName } } -Force | Out-Null
        Set-Alias -Name tree -Value Get-DirectoryTree -Scope Global -ErrorAction SilentlyContinue

        # bat wrapper
        Set-Item -Path Function:global:Show-FileContent -Value { param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs) if ($fileArgs) { if (Get-Command bat -CommandType Application -ErrorAction SilentlyContinue) { & (Get-Command bat -CommandType Application) @fileArgs } else { Get-Content -LiteralPath @fileArgs | Out-Host } } else { if (Get-Command bat -CommandType Application -ErrorAction SilentlyContinue) { & (Get-Command bat -CommandType Application) } else { $input | Out-Host } } } -Force | Out-Null
        Set-Alias -Name bat-cat -Value Show-FileContent -Scope Global -ErrorAction SilentlyContinue
    }
}

# Initialize the functions
Ensure-FileListing
