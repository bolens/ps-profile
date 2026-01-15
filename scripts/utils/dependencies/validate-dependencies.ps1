<#
scripts/utils/validate-dependencies.ps1

.SYNOPSIS
    Validates that all required dependencies are installed and available.

.DESCRIPTION
    Checks PowerShell version, required modules, and optional external tools
    against the requirements configuration (modular structure in requirements/
    directory). Reports missing dependencies and
    provides installation instructions.

.PARAMETER InstallMissing
    If specified, attempts to install missing PowerShell modules automatically.

.PARAMETER RequirementsFile
    Path to specific requirements file (optional). If not specified, uses the
    modular requirements loader (requirements/load-requirements.ps1) which
    automatically loads all category files.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\validate-dependencies.ps1

    Validates all dependencies and reports status.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\validate-dependencies.ps1 -InstallMissing

    Validates dependencies and installs missing PowerShell modules.

.NOTES
    Exit Codes:
    - 0 (EXIT_SUCCESS): All required dependencies are available
    - 1 (EXIT_VALIDATION_FAILURE): Required dependencies are missing
    - 2 (EXIT_SETUP_ERROR): Error reading requirements file or installing modules
#>

param(
    [switch]$InstallMissing,

    [string]$RequirementsFile = $null
)

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Command' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Cache' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'DataFile' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'RequirementsLoader' -ScriptPath $PSScriptRoot -DisableNameChecking

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Load requirements file using the new loader
try {
    if ($RequirementsFile) {
        # If specific file provided, use legacy import
        if (-not (Test-Path -Path $RequirementsFile)) {
            Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Requirements file not found: $RequirementsFile"
        }
        if (Get-Command Import-CachedPowerShellDataFile -ErrorAction SilentlyContinue) {
            $requirements = Import-CachedPowerShellDataFile -Path $RequirementsFile -ErrorAction Stop
        }
        else {
            $requirements = Import-PowerShellDataFile -Path $RequirementsFile -ErrorAction Stop
        }
    }
    else {
        # Use new modular loader
        $requirements = Import-Requirements -RepoRoot $repoRoot -UseCache
    }
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to load requirements file: $($_.Exception.Message)" -ErrorRecord $_
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[dependencies.validate] Starting dependency validation"
    Write-Verbose "[dependencies.validate] Install missing: $InstallMissing, Requirements file: $RequirementsFile"
}

Write-ScriptMessage -Message "Validating dependencies..." -LogLevel Info

$allValid = $true
$missingRequired = [System.Collections.Generic.List[string]]::new()
$missingOptional = [System.Collections.Generic.List[string]]::new()
$versionMismatches = [System.Collections.Generic.List[string]]::new()

# Level 1: PowerShell version check start
if ($debugLevel -ge 1) {
    Write-Verbose "[dependencies.validate] Checking PowerShell version"
}

# Check PowerShell version
if ($requirements.PowerShellVersion) {
    $requiredVersion = [Version]$requirements.PowerShellVersion
    $currentVersion = $PSVersionTable.PSVersion
    
    Write-ScriptMessage -Message "Checking PowerShell version..." -LogLevel Info
    Write-ScriptMessage -Message "  Required: $requiredVersion" -LogLevel Info
    Write-ScriptMessage -Message "  Current: $currentVersion" -LogLevel Info
    
    if ($currentVersion -lt $requiredVersion) {
        $allValid = $false
        $versionMismatches.Add("PowerShell version $currentVersion is below required $requiredVersion")
        Write-ScriptMessage -Message "  ✗ PowerShell version mismatch" -IsWarning
    }
    else {
        Write-ScriptMessage -Message "  ✓ PowerShell version OK" -LogLevel Info
    }
}

# Check required modules
if ($requirements.Modules) {
    Write-ScriptMessage -Message "`nChecking PowerShell modules..." -LogLevel Info
    
    # Level 1: Module check start
    if ($debugLevel -ge 1) {
        Write-Verbose "[dependencies.validate] Starting PowerShell module validation"
        Write-Verbose "[dependencies.validate] Modules to check: $($requirements.Modules.Keys.Count)"
    }
    
    $moduleCheckErrors = [System.Collections.Generic.List[string]]::new()
    $moduleCheckStartTime = Get-Date
    foreach ($moduleName in $requirements.Modules.Keys) {
        try {
            $moduleReq = $requirements.Modules[$moduleName]
            $required = $moduleReq.Required
            $requiredVersion = if ($moduleReq.Version) { [Version]$moduleReq.Version } else { $null }
            
            # Check cache first (cache for 5 minutes)
            $cacheKey = "ModuleAvailable_$moduleName"
            $cachedModule = Get-CachedValue -Key $cacheKey
            if ($null -ne $cachedModule) {
                $installedModule = $cachedModule
            }
            else {
                try {
                    $installedModule = Get-Module -ListAvailable -Name $moduleName -ErrorAction Stop
                    # Cache the result (even if null)
                    Set-CachedValue -Key $cacheKey -Value $installedModule -ExpirationSeconds 300
                }
                catch {
                    # If Get-Module fails, treat as not installed
                    $installedModule = $null
                    Set-CachedValue -Key $cacheKey -Value $null -ExpirationSeconds 300
                }
            }
            
            if (-not $installedModule) {
                if ($required) {
                    $allValid = $false
                    $missingRequired.Add($moduleName)
                    Write-ScriptMessage -Message "  ✗ $moduleName (REQUIRED) - Missing" -IsError
                    
                    if ($InstallMissing) {
                        try {
                            Write-ScriptMessage -Message "    Installing $moduleName..." -LogLevel Info
                            Ensure-ModuleAvailable -ModuleName $moduleName -ErrorAction Stop
                            Write-ScriptMessage -Message "    ✓ $moduleName installed" -LogLevel Info
                            $missingRequired.Remove($moduleName) | Out-Null
                        }
                        catch {
                            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                Write-StructuredError -ErrorRecord $_ -OperationName 'dependencies.validate.install-module' -Context @{
                                    module_name = $moduleName
                                }
                            }
                            else {
                                Write-ScriptMessage -Message "    ✗ Failed to install $moduleName`: $($_.Exception.Message)" -IsError
                            }
                        }
                    }
                }
                else {
                    $missingOptional.Add($moduleName)
                    Write-ScriptMessage -Message "  ⚠ $moduleName (OPTIONAL) - Missing" -IsWarning
                }
            }
            else {
                $installedVersion = $installedModule.Version
                if ($requiredVersion -and $installedVersion -lt $requiredVersion) {
                    $allValid = $false
                    $versionMismatches.Add("$moduleName version $installedVersion is below required $requiredVersion")
                    Write-ScriptMessage -Message "  ⚠ $moduleName - Version mismatch (installed: $installedVersion, required: $requiredVersion)" -IsWarning
                }
                else {
                    Write-ScriptMessage -Message "  ✓ $moduleName - Installed (version $installedVersion)" -LogLevel Info
                }
            }
        }
        catch {
            $moduleCheckErrors.Add($moduleName)
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dependencies.validate.check-module' -Context @{
                    module_name = $moduleName
                }
            }
            else {
                Write-ScriptMessage -Message "  ✗ $moduleName - Error checking: $($_.Exception.Message)" -IsError
            }
            # Treat check errors as missing for required modules
            if ($requirements.Modules[$moduleName].Required) {
                $allValid = $false
                if (-not $missingRequired.Contains($moduleName)) {
                    $missingRequired.Add($moduleName)
                }
            }
        }
    }
    if ($moduleCheckErrors.Count -gt 0) {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Some module checks failed" -OperationName 'dependencies.validate.check-module' -Context @{
                failed_modules = $moduleCheckErrors -join ','
                failed_count = $moduleCheckErrors.Count
            } -Code 'ModuleCheckPartialFailure'
        }
    }
    $moduleCheckDuration = ((Get-Date) - $moduleCheckStartTime).TotalMilliseconds
    
    # Level 2: Module check timing
    if ($debugLevel -ge 2) {
        Write-Verbose "[dependencies.validate] Module check completed in ${moduleCheckDuration}ms"
        Write-Verbose "[dependencies.validate] Missing required: $($missingRequired.Count), Missing optional: $($missingOptional.Count), Errors: $($moduleCheckErrors.Count)"
    }
}

# Check external tools
if ($requirements.ExternalTools) {
    Write-ScriptMessage -Message "`nChecking external tools..." -LogLevel Info
    
    # Level 1: Tool check start
    if ($debugLevel -ge 1) {
        Write-Verbose "[dependencies.validate] Starting external tool validation"
        Write-Verbose "[dependencies.validate] Tools to check: $($requirements.ExternalTools.Keys.Count)"
    }
    
    $toolCheckErrors = [System.Collections.Generic.List[string]]::new()
    $toolCheckStartTime = Get-Date
    foreach ($toolName in $requirements.ExternalTools.Keys) {
        try {
            $toolReq = $requirements.ExternalTools[$toolName]
            $required = $toolReq.Required
            
            $isAvailable = Test-CommandAvailable -CommandName $toolName -ErrorAction Stop
            
            if (-not $isAvailable) {
                if ($required) {
                    $allValid = $false
                    $missingRequired.Add($toolName)
                    Write-ScriptMessage -Message "  ✗ $toolName (REQUIRED) - Missing" -IsError
                    
                    if ($toolReq.InstallCommand) {
                        try {
                            $resolvedCmd = if (Get-Command Resolve-InstallCommand -ErrorAction SilentlyContinue) {
                                Resolve-InstallCommand -InstallCommand $toolReq.InstallCommand -PackageName $toolName -ErrorAction Stop
                            }
                            else {
                                # Fallback: resolve platform-specific command manually
                                $platform = if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
                                elseif ($IsLinux) { 'Linux' }
                                elseif ($IsMacOS) { 'macOS' }
                                else { 'Windows' }
                                if ($toolReq.InstallCommand -is [hashtable]) {
                                    $toolReq.InstallCommand[$platform]
                                }
                                else {
                                    $toolReq.InstallCommand
                                }
                            }
                            if ($resolvedCmd) {
                                Write-ScriptMessage -Message "    Install with: $resolvedCmd" -LogLevel Info
                            }
                        }
                        catch {
                            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                                Write-StructuredWarning -Message "Failed to resolve install command" -OperationName 'dependencies.validate.resolve-install' -Context @{
                                    tool_name = $toolName
                                } -Code 'InstallCommandResolutionFailed'
                            }
                        }
                    }
                }
                else {
                    $missingOptional.Add($toolName)
                    Write-ScriptMessage -Message "  ⚠ $toolName (OPTIONAL) - Missing" -IsWarning
                    
                    if ($toolReq.InstallCommand) {
                        try {
                            $resolvedCmd = if (Get-Command Resolve-InstallCommand -ErrorAction SilentlyContinue) {
                                Resolve-InstallCommand -InstallCommand $toolReq.InstallCommand -PackageName $toolName -ErrorAction Stop
                            }
                            else {
                                # Fallback: resolve platform-specific command manually
                                $platform = if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
                                elseif ($IsLinux) { 'Linux' }
                                elseif ($IsMacOS) { 'macOS' }
                                else { 'Windows' }
                                if ($toolReq.InstallCommand -is [hashtable]) {
                                    $toolReq.InstallCommand[$platform]
                                }
                                else {
                                    $toolReq.InstallCommand
                                }
                            }
                            if ($resolvedCmd) {
                                Write-ScriptMessage -Message "    Install with: $resolvedCmd" -LogLevel Info
                            }
                        }
                        catch {
                            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                                Write-StructuredWarning -Message "Failed to resolve install command" -OperationName 'dependencies.validate.resolve-install' -Context @{
                                    tool_name = $toolName
                                } -Code 'InstallCommandResolutionFailed'
                            }
                        }
                    }
                }
            }
            else {
                Write-ScriptMessage -Message "  ✓ $toolName - Available" -LogLevel Info
            }
        }
        catch {
            $toolCheckErrors.Add($toolName)
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dependencies.validate.check-tool' -Context @{
                    tool_name = $toolName
                }
            }
            else {
                Write-ScriptMessage -Message "  ✗ $toolName - Error checking: $($_.Exception.Message)" -IsError
            }
            # Treat check errors as missing for required tools
            if ($requirements.ExternalTools[$toolName].Required) {
                $allValid = $false
                if (-not $missingRequired.Contains($toolName)) {
                    $missingRequired.Add($toolName)
                }
            }
        }
    }
    $toolCheckDuration = ((Get-Date) - $toolCheckStartTime).TotalMilliseconds
    
    # Level 2: Tool check timing
    if ($debugLevel -ge 2) {
        Write-Verbose "[dependencies.validate] Tool check completed in ${toolCheckDuration}ms"
        Write-Verbose "[dependencies.validate] Missing required: $($missingRequired.Count), Missing optional: $($missingOptional.Count), Errors: $($toolCheckErrors.Count)"
    }
    
    if ($toolCheckErrors.Count -gt 0) {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Some tool checks failed" -OperationName 'dependencies.validate.check-tool' -Context @{
                failed_tools = $toolCheckErrors -join ','
                failed_count = $toolCheckErrors.Count
            } -Code 'ToolCheckPartialFailure'
        }
    }
}

# Level 1: Summary generation
if ($debugLevel -ge 1) {
    Write-Verbose "[dependencies.validate] Generating validation summary"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $totalDuration = $moduleCheckDuration + $toolCheckDuration
    Write-Host "  [dependencies.validate] Performance - Module check: ${moduleCheckDuration}ms, Tool check: ${toolCheckDuration}ms, Total: ${totalDuration}ms" -ForegroundColor DarkGray
}

# Summary
Write-ScriptMessage -Message "`nValidation Summary:" -LogLevel Info

if ($missingRequired.Count -eq 0 -and $versionMismatches.Count -eq 0) {
    Write-ScriptMessage -Message "  ✓ All required dependencies are available" -LogLevel Info
    
    if ($missingOptional.Count -gt 0) {
        Write-ScriptMessage -Message "  ⚠ $($missingOptional.Count) optional dependency(ies) missing" -IsWarning
    }
    
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "Dependency validation passed"
}
else {
    Write-ScriptMessage -Message "  ✗ Missing or invalid dependencies found:" -IsError
    
    if ($missingRequired.Count -gt 0) {
        Write-ScriptMessage -Message "    Required: $($missingRequired -join ', ')" -IsError
    }
    
    if ($versionMismatches.Count -gt 0) {
        foreach ($mismatch in $versionMismatches) {
            Write-ScriptMessage -Message "    Version: $mismatch" -IsError
        }
    }
    
    if (-not $InstallMissing) {
        Write-ScriptMessage -Message "`nRun with -InstallMissing to automatically install missing PowerShell modules." -LogLevel Info
    }
    
    Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "Dependency validation failed"
}


