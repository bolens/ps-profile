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
    
    [FragmentTier]$Tier = [FragmentTier]::standard
    
    [string[]]$Environments = @()
)

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities using ModuleImport pattern
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import CommonEnums for FragmentTier enum
$commonEnumsPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import required modules using Import-LibModule
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking

# Convert enum to string
$tierString = $Tier.ToString()

try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

$profileDDir = Join-Path $repoRoot 'profile.d'

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[fragment.new] Creating new fragment: $Name"
    Write-Verbose "[fragment.new] Tier: $tierString, Dependencies: $($Dependencies -join ', ')"
}

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
    Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "Fragment number must be between 00 and 99"
}

$fragmentFileName = "{0:D2}-{1}.ps1" -f $Number, $Name
$fragmentPath = Join-Path $profileDDir $fragmentFileName

# Check if fragment already exists
if (Test-Path $fragmentPath) {
    Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "Fragment already exists: $fragmentPath"
}

# Build header metadata
$headerLines = @()
$headerLines += "# Tier: $tierString"
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
    # Use Test-CachedCommand for command availability checks

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

# Level 1: File creation start
if ($debugLevel -ge 1) {
    Write-Verbose "[fragment.new] Writing fragment file: $fragmentPath"
    Write-Verbose "[fragment.new] Writing README file: $readmePath"
}

# Write files
$writeStartTime = Get-Date
try {
    Set-Content -Path $fragmentPath -Value $fragmentContent -Encoding UTF8
    Write-Host "Created fragment: $fragmentPath" -ForegroundColor Green
    
    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    Write-Host "Created README: $readmePath" -ForegroundColor Green
    
    $writeDuration = ((Get-Date) - $writeStartTime).TotalMilliseconds
    
    # Level 2: Timing information
    if ($debugLevel -ge 2) {
        Write-Verbose "[fragment.new] Files created in ${writeDuration}ms"
    }
    
    # Level 3: Performance breakdown
    if ($debugLevel -ge 3) {
        $fragmentSize = (Get-Item $fragmentPath).Length
        $readmeSize = (Get-Item $readmePath).Length
        Write-Host "  [fragment.new] Performance - Write: ${writeDuration}ms, Fragment: ${fragmentSize} bytes, README: ${readmeSize} bytes" -ForegroundColor DarkGray
    }
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Edit $fragmentFileName to implement your functionality" -ForegroundColor Yellow
    Write-Host "2. Update the README with function documentation" -ForegroundColor Yellow
    Write-Host "3. Test the fragment by reloading your profile: . `$PROFILE" -ForegroundColor Yellow
    
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "Fragment created successfully"
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName 'fragment.new.create' -Context @{
            fragment_name = $fragmentFileName
            fragment_path = $fragmentPath
            readme_path = $readmePath
        }
    }
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}


