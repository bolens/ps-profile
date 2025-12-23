<#
scripts/utils/code-quality/modules/OutputInterceptor.psm1

.SYNOPSIS
    Output interception utilities.

.DESCRIPTION
    Provides functions for intercepting Write-Host and Write-Warning to sanitize output.
#>

# Import sanitizer
$sanitizerModulePath = Join-Path $PSScriptRoot 'OutputSanitizer.psm1'
if ($sanitizerModulePath -and -not [string]::IsNullOrWhiteSpace($sanitizerModulePath) -and (Test-Path -LiteralPath $sanitizerModulePath)) {
    Import-Module $sanitizerModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Script-level variables for output interception
$script:OriginalWriteHostScriptBlock = $null
$script:OriginalWriteWarningScriptBlock = $null
$script:WriteHostOverrideActive = $false
$script:WriteWarningOverrideActive = $false
$script:EmittedWarningMessages = $null

<#
.SYNOPSIS
    Starts intercepting Write-Host output to sanitize test runner messages.

.DESCRIPTION
    Temporarily replaces Write-Host with a wrapper that rewrites absolute repository
    paths before delegating to the original implementation. Subsequent calls are
    ignored until Stop-TestOutputInterceptor is invoked.
#>
function Start-TestOutputInterceptor {
    if ($script:OriginalWriteHostScriptBlock -or $script:WriteHostOverrideActive) {
        return
    }

    $script:OriginalWriteHostScriptBlock = $null
    $script:WriteHostOverrideActive = $false
    $script:OriginalWriteWarningScriptBlock = $null
    $script:WriteWarningOverrideActive = $false
    $script:EmittedWarningMessages = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    try {
        $command = Get-Command -Name Write-Host -ErrorAction Stop
        if ($command.CommandType -eq 'Function') {
            $script:OriginalWriteHostScriptBlock = $command.ScriptBlock
        }
    }
    catch {
        return
    }

    <#
    .SYNOPSIS
        Overrides Write-Host to sanitize emitted repository paths.

    .DESCRIPTION
        Invoked while tests run to rewrite any absolute repository paths to
        relative equivalents before delegating to the original Write-Host
        implementation.
    #>
    function global:RunPester_WriteHostOverride {
        [CmdletBinding()]
        param(
            [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
            [object[]]$Object,
            [ConsoleColor]$ForegroundColor,
            [ConsoleColor]$BackgroundColor,
            [switch]$NoNewLine,
            [object]$Separator = ' '
        )

        $processedObject = $Object
        if ($processedObject) {
            $processedObject = foreach ($item in $processedObject) {
                if ($item -is [string]) { Convert-TestOutputLine -Text $item } else { $item }
            }
        }

        $arguments = @{ }
        foreach ($entry in $PSBoundParameters.GetEnumerator()) {
            if ($entry.Key -eq 'Object') {
                $arguments[$entry.Key] = $processedObject
            }
            else {
                $arguments[$entry.Key] = $entry.Value
            }
        }

        if (-not $arguments.ContainsKey('Object')) {
            $arguments['Object'] = $processedObject
        }

        Microsoft.PowerShell.Utility\Write-Host @arguments
    }

    Set-Item -Path Function:\Write-Host -Value ${function:RunPester_WriteHostOverride} -Force
    $script:WriteHostOverrideActive = $true

    try {
        $warningCommand = Get-Command -Name Write-Warning -ErrorAction Stop
        if ($warningCommand.CommandType -eq 'Function') {
            $script:OriginalWriteWarningScriptBlock = $warningCommand.ScriptBlock
        }
    }
    catch {
    }

    <#
    .SYNOPSIS
        Overrides Write-Warning to deduplicate and sanitize messages.

    .DESCRIPTION
        Ensures noisy warnings only appear once per unique message while still
        passing through repository path sanitation.
    #>
    function global:RunPester_WriteWarningOverride {
        [CmdletBinding()]
        param(
            [Parameter(Position = 0, Mandatory, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
            [object]$Message
        )

        process {
            $text = if ($null -ne $Message) { [string]$Message } else { [string]::Empty }
            $converted = Convert-TestOutputLine -Text $text
            if ([string]::IsNullOrWhiteSpace($converted)) {
                $converted = $text
            }

            if (-not $script:EmittedWarningMessages) {
                $script:EmittedWarningMessages = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }

            if ($script:EmittedWarningMessages.Add($converted)) {
                $arguments = @{ }
                foreach ($entry in $PSBoundParameters.GetEnumerator()) {
                    if ($entry.Key -eq 'Message') {
                        $arguments[$entry.Key] = $converted
                    }
                    else {
                        $arguments[$entry.Key] = $entry.Value
                    }
                }

                if (-not $arguments.ContainsKey('Message')) {
                    $arguments['Message'] = $converted
                }

                if ($script:OriginalWriteWarningScriptBlock) {
                    & $script:OriginalWriteWarningScriptBlock @arguments
                }
                else {
                    Microsoft.PowerShell.Utility\Write-Warning @arguments
                }
            }
        }
    }

    Set-Item -Path Function:\Write-Warning -Value ${function:RunPester_WriteWarningOverride} -Force
    $script:WriteWarningOverrideActive = $true
}

<#
.SYNOPSIS
    Restores the original Write-Host implementation after interception.

.DESCRIPTION
    Replaces the temporary wrapper installed by Start-TestOutputInterceptor with the
    previously captured Write-Host script block. Subsequent calls are ignored once the
    original function has been restored.
#>
function Stop-TestOutputInterceptor {
    if (-not $script:WriteHostOverrideActive) {
        if (-not $script:WriteWarningOverrideActive) {
            return
        }
    }

    if ($script:WriteHostOverrideActive) {
        if ($script:OriginalWriteHostScriptBlock) {
            Set-Item -Path Function:\Write-Host -Value $script:OriginalWriteHostScriptBlock -Force
        }
        else {
            Remove-Item -Path Function:\Write-Host -Force -ErrorAction SilentlyContinue
        }

        Remove-Item -Path Function:\RunPester_WriteHostOverride -Force -ErrorAction SilentlyContinue
        $script:OriginalWriteHostScriptBlock = $null
        $script:WriteHostOverrideActive = $false
    }

    if ($script:WriteWarningOverrideActive) {
        if ($script:OriginalWriteWarningScriptBlock) {
            Set-Item -Path Function:\Write-Warning -Value $script:OriginalWriteWarningScriptBlock -Force
        }
        else {
            Remove-Item -Path Function:\Write-Warning -Force -ErrorAction SilentlyContinue
        }

        Remove-Item -Path Function:\RunPester_WriteWarningOverride -Force -ErrorAction SilentlyContinue
        $script:OriginalWriteWarningScriptBlock = $null
        $script:WriteWarningOverrideActive = $false
        $script:EmittedWarningMessages = $null
    }
}

Export-ModuleMember -Function @(
    'Start-TestOutputInterceptor',
    'Stop-TestOutputInterceptor'
)

