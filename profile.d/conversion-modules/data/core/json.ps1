# ===============================================
# JSON format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes JSON format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for JSON format operations.
    Supports JSON pretty-printing.
    This function is called automatically by Initialize-FileConversion-CoreBasic.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-CoreBasicJson {
    # JSON pretty-print
    Set-Item -Path Function:Global:_Format-Json -Value {
        param(
            [Parameter(ValueFromPipeline = $true)]
            $InputObject,
            [Parameter(ValueFromRemainingArguments = $true)]
            $fileArgs
        )
        process {
            $rawInput = $null
            try {
                if ($fileArgs) {
                    $rawInput = Get-Content -Raw -LiteralPath @fileArgs
                    $rawInput | ConvertFrom-Json -ErrorAction Stop | ConvertTo-Json -Depth 10
                }
                elseif ($PSBoundParameters.ContainsKey('InputObject') -and $null -ne $InputObject) {
                    $rawInput = $InputObject
                    $rawInput | ConvertFrom-Json -ErrorAction Stop | ConvertTo-Json -Depth 10
                }
                else {
                    $rawInput = $input | Out-String
                    if ([string]::IsNullOrWhiteSpace($rawInput)) {
                        return
                    }
                    $rawInput | ConvertFrom-Json -ErrorAction Stop | ConvertTo-Json -Depth 10
                }
            }
            catch {
                # Only show warning when not running in Pester tests
                if (-not (Get-Module -Name Pester -ErrorAction SilentlyContinue)) {
                    Write-Warning "Failed to pretty-print JSON: $($_.Exception.Message)"
                }
                if ($null -ne $rawInput) {
                    Write-Output $rawInput
                }
            }
        }
    } -Force
}

# Public functions and aliases
# Pretty-print JSON
<#
.SYNOPSIS
    Pretty-prints JSON data.
.DESCRIPTION
    Formats JSON data with proper indentation and structure.
#>
function Format-Json {
    param([Parameter(ValueFromPipeline = $true)] $InputObject, [Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        & "Global:_Format-Json" @PSBoundParameters
    }
    catch {
        Write-Error "Failed to pretty-print JSON: $($_.Exception.Message)"
        throw
    }
}
# Use Set-AgentModeAlias if available, otherwise Set-Alias in Global scope
if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'json-pretty' -Target 'Format-Json'
}
else {
    Set-Alias -Name json-pretty -Value Format-Json -Scope Global -ErrorAction SilentlyContinue
}

