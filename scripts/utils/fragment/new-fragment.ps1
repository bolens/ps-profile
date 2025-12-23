<#
scripts/utils/new-fragment.ps1

.SYNOPSIS
    Creates a new profile fragment with proper structure and boilerplate.

.DESCRIPTION
    Generates a new profile fragment file with:
    - Proper idempotency checks
    - Error handling boilerplate
    - Comment-based help structure
    - Associated README template

.PARAMETER Name
    The name of the fragment (without .ps1 extension). Will be prefixed with a number.

.PARAMETER Number
    Optional. Fragment number prefix (00-99). If not provided, uses next available number.

.PARAMETER Dependencies
    Optional. Array of fragment names that this fragment depends on. Defaults to 'bootstrap'.

.PARAMETER Description
    Optional. Brief description of what the fragment does.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\new-fragment.ps1 -Name 'my-feature' -Number 50

    Creates profile.d/my-feature.ps1 with proper structure.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\new-fragment.ps1 -Name 'custom-tools' -Dependencies @('bootstrap', 'env', 'utilities')

    Creates a new fragment that depends on bootstrap and env fragments.
#>

param(
    [Parameter(Mandatory)]
    [string]$Name,
    
    [int]$Number = -1,
    
    [string[]]$Dependencies = @('bootstrap'),
    
    [string]$Description = "Profile fragment for $Name",
    
    [ValidateSet('core', 'essential', 'standard', 'optional')]
    [string]$Tier = 'standard',
    
    [string[]]$Environments = @()
)

# Import shared utilities using ModuleImport pattern
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import required modules using Import-LibModule
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking

try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$profileDDir = Join-Path $repoRoot 'profile.d'

# Determine fragment number
if ($Number -lt 0) {
    # Find the highest numbered fragment
    $existingFragments = Get-ChildItem -Path $profileDDir -Filter '*.ps1' -File | 
    Where-Object { $_.Name -match '^(\d+)-' } |
    ForEach-Object { 
        if ($_.Name -match '^(\d+)-') {
            [int]$matches[1]
        }
    }
    
    if ($existingFragments) {
        $Number = ($existingFragments | Measure-Object -Maximum).Maximum + 1
    }
    else {
        $Number = 0
    }
}

# Ensure number is in valid range
if ($Number -lt 0 -or $Number -gt 99) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Fragment number must be between 00 and 99"
}

$fragmentFileName = "{0:D2}-{1}.ps1" -f $Number, $Name
$fragmentPath = Join-Path $profileDDir $fragmentFileName

# Check if fragment already exists
if (Test-Path $fragmentPath) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Fragment already exists: $fragmentPath"
}

# Build header metadata
$headerLines = @()
$headerLines += "# Tier: $Tier"
if ($Dependencies.Count -gt 0) {
    $depsString = $Dependencies -join ', '
    $headerLines += "# Dependencies: $depsString"
}
if ($Environments.Count -gt 0) {
    $envString = $Environments -join ', '
    $headerLines += "# Environment: $envString"
}
$headerMetadata = $headerLines -join "`n"

# Generate fragment content
$fragmentContent = @"
<#
# $fragmentFileName
#
$Description
#>

$headerMetadata

try {
    if (`$null -ne (Get-Variable -Name '${Name}Loaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # Fragment implementation here
    # Use Set-AgentModeFunction or Set-AgentModeAlias for collision-safe registration
    # Use Test-CachedCommand or Test-HasCommand for command availability checks

    Set-Variable -Name '${Name}Loaded' -Value `$true -Scope Global -Force
}
catch {
    if (`$env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord `$_ -Context "Fragment: $fragmentFileName" -Category 'Fragment'
        } else {
            Write-Verbose "$fragmentFileName failed: `$(`$_.Exception.Message)"
        }
    }
}
"@

# Generate README content
$readmeFileName = "$fragmentFileName.README.md"
$readmePath = Join-Path $profileDDir $readmeFileName

$readmeContent = @"
$fragmentFileName
$(('=' * $fragmentFileName.Length))

Purpose
-------

$Description

Usage
-----

See the fragment source: \`$fragmentFileName\` for examples and usage notes.

Functions
---------

<!-- List functions and aliases defined by this fragment -->

Dependencies
------------

$(($Dependencies | ForEach-Object { "- \`$_" }) -join "`n")

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
"@

# Write files
try {
    Set-Content -Path $fragmentPath -Value $fragmentContent -Encoding UTF8
    Write-Host "Created fragment: $fragmentPath" -ForegroundColor Green
    
    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    Write-Host "Created README: $readmePath" -ForegroundColor Green
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Edit $fragmentFileName to implement your functionality" -ForegroundColor Yellow
    Write-Host "2. Update the README with function documentation" -ForegroundColor Yellow
    Write-Host "3. Test the fragment by reloading your profile: . `$PROFILE" -ForegroundColor Yellow
    
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Fragment created successfully"
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}


