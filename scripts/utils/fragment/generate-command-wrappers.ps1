<#
scripts/utils/fragment/generate-command-wrappers.ps1

.SYNOPSIS
    Generates standalone script wrappers for fragment commands.

.DESCRIPTION
    Creates executable PowerShell script wrappers in scripts/bin/ that can invoke
    fragment commands without requiring the full profile to be loaded. Each wrapper:
    - Loads the required fragment and its dependencies
    - Executes the command with all provided arguments
    - Handles errors appropriately
    - Can be called from any shell or script

.PARAMETER OutputPath
    The output directory for generated wrappers. Defaults to "scripts/bin".

.PARAMETER CommandName
    If specified, generates a wrapper for only this command. Otherwise, generates
    wrappers for all registered commands.

.PARAMETER Force
    If specified, overwrites existing wrapper files. Otherwise, existing files are skipped.

.PARAMETER DryRun
    If specified, shows what wrappers would be generated without actually creating files.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\fragment\generate-command-wrappers.ps1

    Generates wrappers for all registered commands in scripts/bin/.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\fragment\generate-command-wrappers.ps1 -CommandName 'Invoke-Aws'

    Generates a wrapper only for the Invoke-Aws command.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\fragment\generate-command-wrappers.ps1 -Force

    Regenerates all wrappers, overwriting existing ones.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\fragment\generate-command-wrappers.ps1 -DryRun

    Shows what wrappers would be generated without actually creating them.
#>

param(
    [string]$OutputPath = $null,

    [string]$CommandName = $null,

    [switch]$Force,

    [switch]$DryRun
)

# Import ModuleImport first (bootstrap)
$repoRootForLib = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$moduleImportPath = Join-Path $repoRootForLib 'scripts' 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Import fragment modules
$fragmentLibDir = Join-Path $repoRootForLib 'scripts' 'lib' 'fragment'
$registryModulePath = Join-Path $fragmentLibDir 'FragmentCommandRegistry.psm1'
$loaderModulePath = Join-Path $fragmentLibDir 'FragmentLoader.psm1'

if (-not (Test-Path -LiteralPath $registryModulePath)) {
    Write-Error "FragmentCommandRegistry module not found at: $registryModulePath"
    Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Required module not found"
}

Import-Module $registryModulePath -DisableNameChecking -ErrorAction Stop

if (Test-Path -LiteralPath $loaderModulePath) {
    Import-Module $loaderModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Determine output path
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $repoRootForLib 'scripts' 'bin'
}

# Ensure output directory exists
if (-not $DryRun) {
    if (-not (Test-Path -LiteralPath $OutputPath)) {
        try {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
            Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to create output directory: $($_.Exception.Message)"
            Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
        }
    }
}

# Get repository root
$repoRoot = $repoRootForLib
$profileDir = Join-Path $repoRoot 'profile.d'

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[fragment.generate-wrappers] Starting command wrapper generation"
    Write-Verbose "[fragment.generate-wrappers] Output path: $OutputPath"
    Write-Verbose "[fragment.generate-wrappers] Command name: $CommandName, Force: $Force, Dry run: $DryRun"
}

# Get all registered commands
$commands = @{}
try {
    if (-not [string]::IsNullOrWhiteSpace($CommandName)) {
        # Single command requested
        try {
            if (Get-Command Get-CommandRegistryInfo -ErrorAction SilentlyContinue) {
                $info = Get-CommandRegistryInfo -CommandName $CommandName
                if ($info) {
                    $commands[$CommandName] = $info
                }
            }
            elseif (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) {
                if ($global:FragmentCommandRegistry.ContainsKey($CommandName)) {
                    $commands[$CommandName] = $global:FragmentCommandRegistry[$CommandName]
                }
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'wrapper-generator.get-command' -Context @{
                    command_name = $CommandName
                }
            }
            else {
                Write-Error "Failed to get command info for '$CommandName': $($_.Exception.Message)"
            }
        }
    }
    else {
        # All commands
        try {
            if (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) {
                foreach ($cmdName in $global:FragmentCommandRegistry.Keys) {
                    try {
                        if (Get-Command Get-CommandRegistryInfo -ErrorAction SilentlyContinue) {
                            $info = Get-CommandRegistryInfo -CommandName $cmdName
                            if ($info) {
                                $commands[$cmdName] = $info
                            }
                        }
                        else {
                            # Fallback: use registry entry directly
                            $entry = $global:FragmentCommandRegistry[$cmdName]
                            if ($entry) {
                                $commands[$cmdName] = $entry
                            }
                        }
                    }
                    catch {
                        # Skip invalid entries
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "Skipping invalid command entry: $cmdName" -OperationName 'wrapper-generator.get-commands' -Context @{
                                command_name = $cmdName
                            } -Code 'InvalidRegistryEntry'
                        }
                    }
                }
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'wrapper-generator.get-commands' -Context @{}
            }
            else {
                Write-Error "Failed to get commands from registry: $($_.Exception.Message)"
            }
        }
    }
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName 'wrapper-generator.get-commands' -Context @{
            command_name = $CommandName
        }
    }
    else {
        Write-Error "Failed to retrieve commands from registry: $($_.Exception.Message)"
    }
    Exit-WithCode -ExitCode [ExitCode]::RuntimeError -ErrorRecord $_
}

if ($commands.Count -eq 0) {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        Write-StructuredWarning -Message "No commands found in registry" -OperationName 'wrapper-generator.setup' -Context @{} -Code 'NoCommandsFound'
    }
    else {
        Write-Warning "No commands found in registry. Make sure the profile has been loaded at least once to populate the registry."
    }
    Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "No commands to generate wrappers for"
}

Write-Host "Found $($commands.Count) command(s) to generate wrappers for" -ForegroundColor Cyan

# Generate wrapper for each command
$generated = 0
$skipped = 0
$errors = 0

# Level 2: Command list details
if ($debugLevel -ge 2) {
    Write-Verbose "[fragment.generate-wrappers] Commands to process: $($commands.Keys -join ', ')"
}

$genStartTime = Get-Date
foreach ($cmdName in $commands.Keys) {
    # Level 1: Individual command processing
    if ($debugLevel -ge 1) {
        Write-Verbose "[fragment.generate-wrappers] Generating wrapper for command: $cmdName"
    }
    
    $cmdStartTime = Get-Date
    try {
        $cmdInfo = $commands[$cmdName]
        if (-not $cmdInfo) {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Skipping command with null info: $cmdName" -OperationName 'wrapper-generator.process' -Context @{
                    command_name = $cmdName
                } -Code 'InvalidCommandInfo'
            }
            $skipped++
            continue
        }

        $fragmentName = $cmdInfo.Fragment
        $cmdType = $cmdInfo.Type

        if ([string]::IsNullOrWhiteSpace($fragmentName) -or [string]::IsNullOrWhiteSpace($cmdType)) {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Skipping command with invalid fragment or type: $cmdName" -OperationName 'wrapper-generator.process' -Context @{
                    command_name  = $cmdName
                    fragment_name = $fragmentName
                    command_type  = $cmdType
                } -Code 'InvalidCommandInfo'
            }
            $skipped++
            continue
        }

        # Skip aliases - they're not directly executable
        if ($cmdType -eq 'Alias') {
            if ($DryRun) {
                Write-Host "  [SKIP] $cmdName (alias)" -ForegroundColor Yellow
            }
            $skipped++
            continue
        }

        $wrapperPath = Join-Path $OutputPath "$cmdName.ps1"

        # Check if file exists
        if (-not $Force -and (Test-Path -LiteralPath $wrapperPath)) {
            if ($DryRun) {
                Write-Host "  [SKIP] $cmdName (exists, use -Force to overwrite)" -ForegroundColor Yellow
            }
            else {
                Write-Verbose "Skipping $cmdName - wrapper already exists (use -Force to overwrite)"
            }
            $skipped++
            continue
        }

        if ($DryRun) {
            Write-Host "  [GENERATE] $cmdName -> $wrapperPath" -ForegroundColor Green
            $generated++
            continue
        }

        try {
            # Generate wrapper content
            $wrapperContent = @"
# Generated wrapper for $cmdName
# Source fragment: $fragmentName
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# DO NOT EDIT - This file is auto-generated

param(
    [Parameter(ValueFromRemainingArguments = `$true)]
    `$Arguments
)

# Get repository root (this script is in scripts/bin/, repo root is 2 levels up)
`$repoRoot = Split-Path -Parent (Split-Path -Parent `$PSScriptRoot)
`$profileDir = Join-Path `$repoRoot 'profile.d'
`$fragmentPath = Join-Path `$profileDir "$fragmentName.ps1"

# Check if fragment exists
if (-not (Test-Path -LiteralPath `$fragmentPath)) {
    Write-Error "Fragment file not found: `$fragmentPath"
    exit 1
}

# Load fragment dependencies if FragmentLoader is available
`$fragmentLibDir = Join-Path `$repoRoot 'scripts' 'lib' 'fragment'
`$loaderModulePath = Join-Path `$fragmentLibDir 'FragmentLoader.psm1'
if (Test-Path -LiteralPath `$loaderModulePath) {
    try {
        Import-Module `$loaderModulePath -DisableNameChecking -ErrorAction SilentlyContinue
        if (Get-Command Load-Fragment -ErrorAction SilentlyContinue) {
            `$null = Load-Fragment -FragmentName '$fragmentName'
        }
        else {
            # Fallback: dot-source fragment directly
            . `$fragmentPath
        }
    }
    catch {
        # If loader fails, try direct dot-source
        . `$fragmentPath
    }
}
else {
    # Fallback: dot-source fragment directly
    . `$fragmentPath
}

# Execute command
if (Get-Command '$cmdName' -ErrorAction SilentlyContinue) {
    try {
        & '$cmdName' @Arguments
        exit `$LASTEXITCODE
    }
    catch {
        Write-Error "Failed to execute command '$cmdName': `$(`$_.Exception.Message)"
        exit 1
    }
}
else {
    Write-Error "Command '$cmdName' not found after loading fragment '$fragmentName'"
    exit 1
}
"@

            # Write wrapper file
            try {
                Set-Content -Path $wrapperPath -Value $wrapperContent -Encoding UTF8 -NoNewline
                Write-Host "  [GENERATED] $cmdName -> $wrapperPath" -ForegroundColor Green
                $generated++
            }
            catch {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'wrapper-generator.write' -Context @{
                        command_name = $cmdName
                        wrapper_path = $wrapperPath
                    }
                }
                else {
                    Write-Error "Failed to write wrapper for $cmdName : $($_.Exception.Message)"
                }
                $errors++
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'wrapper-generator.generate' -Context @{
                    command_name  = $cmdName
                    fragment_name = $fragmentName
                }
            }
            else {
                Write-Error "Failed to generate wrapper for $cmdName : $($_.Exception.Message)"
            }
            $errors++
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'wrapper-generator.process' -Context @{
                command_name = $cmdName
            }
        }
        else {
            Write-Error "Failed to process command $cmdName : $($_.Exception.Message)"
        }
        $errors++
    }
    
    $cmdDuration = ((Get-Date) - $cmdStartTime).TotalMilliseconds
    
    # Level 2: Command processing timing
    if ($debugLevel -ge 2) {
        Write-Verbose "[fragment.generate-wrappers] Command $cmdName processed in ${cmdDuration}ms"
    }
}

$genDuration = ((Get-Date) - $genStartTime).TotalMilliseconds

# Level 2: Overall generation timing
if ($debugLevel -ge 2) {
    Write-Verbose "[fragment.generate-wrappers] Generation completed in ${genDuration}ms"
    Write-Verbose "[fragment.generate-wrappers] Generated: $generated, Skipped: $skipped, Errors: $errors"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $avgCmdTime = if ($commands.Count -gt 0) { $genDuration / $commands.Count } else { 0 }
    Write-Host "  [fragment.generate-wrappers] Performance - Duration: ${genDuration}ms, Avg per command: ${avgCmdTime}ms, Commands: $($commands.Count), Generated: $generated" -ForegroundColor DarkGray
}

# Summary
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Generated: $generated" -ForegroundColor Green
Write-Host "  Skipped: $skipped" -ForegroundColor Yellow
if ($errors -gt 0) {
    Write-Host "  Errors: $errors" -ForegroundColor Red
    Exit-WithCode -ExitCode [ExitCode]::RuntimeError -Message "Errors occurred during wrapper generation"
}

if (-not $DryRun) {
    Write-Host ""
    Write-Host "To use these wrappers, add the following to your PATH:" -ForegroundColor Cyan
    Write-Host "  $OutputPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or on Windows, run:" -ForegroundColor Cyan
    Write-Host "  `$env:Path += `";$OutputPath`"" -ForegroundColor Yellow
}

Exit-WithCode -ExitCode [ExitCode]::Success
