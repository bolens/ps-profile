<#
# 33-aliases.ps1

Register user aliases and small interactive helper functions in an
idempotent, non-destructive way.
#>

# Define Enable-Aliases function
<#
.SYNOPSIS
    Enables user-defined aliases and helper functions for enhanced shell experience.

.DESCRIPTION
    Registers common aliases and small interactive helper functions in an idempotent way.
    This includes enhanced directory listing functions and PATH display utilities.
    The function ensures aliases are only loaded once per session.

.EXAMPLE
    Enable-Aliases

    Enables all user-defined aliases for the current session.
#>
function Enable-Aliases {
    param()
    try {
        if (-not (Get-Variable -Name 'AliasesLoaded' -Scope Global -ErrorAction SilentlyContinue)) {
            # List directory contents - enhanced ls
            Set-Item -Path Function:Get-ChildItemEnhanced -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) Get-ChildItem @a } -Force | Out-Null
            Set-Alias -Name ll -Value Get-ChildItemEnhanced -ErrorAction SilentlyContinue
            # List all directory contents - enhanced ls -a
            Set-Item -Path Function:Get-ChildItemEnhancedAll -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) Get-ChildItem -Force @a } -Force | Out-Null
            Set-Alias -Name la -Value Get-ChildItemEnhancedAll -ErrorAction SilentlyContinue
            # Show PATH entries as an array
            Set-Item -Path Function:Show-Path -Value { $env:Path -split ';' | Where-Object { $_ } } -Force | Out-Null
            Set-Variable -Name 'AliasesLoaded' -Value $true -Scope Global -Force
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Enable-Aliases failed: $($_.Exception.Message)" }
    }
}

try {
    # Alias registration is done on-demand to keep dot-source cheap.
    # We expose Enable-Aliases which will create the function/alias
    # definitions when called. This keeps startup fast and preserves
    # behavior for interactive use when the user asks for aliases.

    # Optionally auto-enable aliases in interactive sessions when explicitly requested
    if ($env:PS_PROFILE_AUTOENABLE_ALIASES -eq '1') { Enable-Aliases }
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Aliases fragment failed: $($_.Exception.Message)" }
}
