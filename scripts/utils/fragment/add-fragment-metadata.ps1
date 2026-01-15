<#
scripts/utils/fragment/add-fragment-metadata.ps1

.SYNOPSIS
    Adds missing metadata tags (Tier, Dependencies, Environment) to fragment files.

.DESCRIPTION
    Scans all fragments in profile.d/ and adds missing metadata tags based on:
    - Fragment name patterns
    - Existing dependencies
    - Fragment purpose

.PARAMETER Fragment
    Optional. Specific fragment name to update. If not provided, updates all fragments.

.PARAMETER DryRun
    If set, shows what would be changed without modifying files.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/fragment/add-fragment-metadata.ps1

    Adds missing metadata to all fragments.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/fragment/add-fragment-metadata.ps1 -Fragment 'go' -DryRun

    Shows what would be added to go.ps1.
#>

param(
    [string]$Fragment,
    [switch]$DryRun
)

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Resolve repo root
$repoRoot = $PSScriptRoot
for ($i = 1; $i -le 3; $i++) {
    $repoRoot = Split-Path -Parent $repoRoot
}

$profileDDir = Join-Path $repoRoot 'profile.d'
if (-not (Test-Path $profileDDir)) {
    Write-Error "profile.d directory not found: $profileDDir"
    exit 1
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[fragment.add-metadata] Starting fragment metadata addition"
    if ($Fragment) {
        Write-Verbose "[fragment.add-metadata] Target fragment: $Fragment"
    }
    else {
        Write-Verbose "[fragment.add-metadata] Processing all fragments"
    }
    Write-Verbose "[fragment.add-metadata] Dry run: $DryRun"
}

# Get fragments to process
$fragments = if ($Fragment) {
    $fragmentPath = Join-Path $profileDDir "$Fragment.ps1"
    if (Test-Path $fragmentPath) {
        @(Get-Item $fragmentPath)
    }
    else {
        Write-Error "Fragment not found: $Fragment"
        exit 1
    }
}
else {
    Get-ChildItem -Path $profileDDir -Filter '*.ps1' -File |
    Where-Object { 
        $_.Name -ne 'files-module-registry.ps1' -and
        $_.DirectoryName -eq $profileDDir
    }
}

# Import fragment loading module for dependency detection
$fragmentLoadingPath = Join-Path $repoRoot 'scripts' 'lib' 'fragment' 'FragmentLoading.psm1'
if (Test-Path $fragmentLoadingPath) {
    Import-Module $fragmentLoadingPath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Define tier mapping based on fragment names
$tierMapping = @{
    'bootstrap'        = 'core'
    'env'              = 'essential'
    'files'            = 'essential'
    'utilities'        = 'essential'
    'system'           = 'essential'
    'git'              = 'essential'
    'ssh'              = 'essential'
    'kubectl'          = 'essential'
    'kube'             = 'essential'
    'terraform'        = 'essential'
    'ansible'          = 'essential'
    'jq-yq'            = 'essential'
    'rg'               = 'essential'
    'fzf'              = 'essential'
    'rclone'           = 'essential'
    'wsl'              = 'essential'
    'clipboard'        = 'essential'
    'shortcuts'        = 'essential'
    'scoop'            = 'essential'
    'scoop-completion' = 'essential'
    'oh-my-posh'       = 'essential'
    'starship'         = 'essential'
    'psreadline'       = 'essential'
    'containers'       = 'essential'
    'minio'            = 'essential'
    'lazydocker'       = 'essential'
    'system-info'      = 'essential'
}

# Define default dependencies
$defaultDependencies = @{
    'bootstrap' = @()
    'env'       = @('bootstrap')
}

# Define environment assignments based on fragment purpose
$environmentMapping = @{
    'aws'                 = @('cloud', 'development')
    'azure'               = @('cloud', 'development')
    'gcloud'              = @('cloud', 'development')
    'terraform'           = @('cloud', 'development', 'iac-tools')
    'kubectl'             = @('cloud', 'containers', 'development')
    'kube'                = @('cloud', 'containers', 'development')
    'helm'                = @('cloud', 'containers', 'development')
    'containers'          = @('containers', 'development')
    'containers-enhanced' = @('containers', 'development')
    'kubernetes-enhanced' = @('cloud', 'containers', 'development')
    'cloud-enhanced'      = @('cloud', 'development')
    'iac-tools'           = @('cloud', 'development')
    'npm'                 = @('web', 'development')
    'pnpm'                = @('web', 'development')
    'yarn'                = @('web', 'development')
    'bun'                 = @('web', 'development')
    'package-managers'    = @('web', 'development')
    'angular'             = @('web', 'development')
    'nextjs'              = @('web', 'development')
    'nuxt'                = @('web', 'development')
    'vue'                 = @('web', 'development')
    'vite'                = @('web', 'development')
    'laravel'             = @('web', 'development')
    'firebase'            = @('web', 'development')
    'ngrok'               = @('web', 'development')
    'open'                = @('web', 'development')
    'build-tools'         = @('web', 'development')
    'dev'                 = @('web', 'development')
    'api-tools'           = @('web', 'development')
    'modern-cli'          = @('web', 'development')
    'testing'             = @('testing', 'development')
    'diagnostics'         = @('testing', 'ci', 'development')
    'error-handling'      = @('testing', 'ci', 'development')
    'database'            = @('server', 'development')
    'database-clients'    = @('server', 'development')
    'network-utils'       = @('server', 'development')
    'network-analysis'    = @('server', 'development')
    'security-tools'      = @('server', 'development')
    'system-monitor'      = @('server', 'development')
    'system-info'         = @('server', 'development')
    'ssh'                 = @('server', 'development')
}

$updated = 0
$skipped = 0

$processErrors = [System.Collections.Generic.List[string]]::new()
$processStartTime = Get-Date
$updated = 0
$skipped = 0
foreach ($file in $fragments) {
    $baseName = $file.BaseName
    
    # Level 1: Individual fragment processing
    if ($debugLevel -ge 1) {
        Write-Verbose "[fragment.add-metadata] Processing fragment: $($file.Name)"
    }
    
    $fileStartTime = Get-Date
    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        
        if ([string]::IsNullOrWhiteSpace($content)) {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Skipping empty fragment file" -OperationName 'fragment.add-metadata' -Context @{
                    fragment_name = $file.Name
                } -Code 'EmptyFragmentFile'
            }
            else {
                Write-Warning "Skipping empty file: $($file.Name)"
            }
            $skipped++
            continue
        }
    
    # Remove duplicate metadata lines if they exist
    $lines = $content -split "`r?`n"
    $cleanedLines = @()
    $seenTier = $false
    $seenDependencies = $false
    $seenEnvironment = $false
    
    foreach ($line in $lines) {
        if ($line -match '^\s*#\s*Tier\s*:') {
            if (-not $seenTier) {
                $cleanedLines += $line
                $seenTier = $true
            }
            # Skip duplicate
        }
        elseif ($line -match '^\s*#\s*Dependencies\s*:') {
            if (-not $seenDependencies) {
                $cleanedLines += $line
                $seenDependencies = $true
            }
            # Skip duplicate
        }
        elseif ($line -match '^\s*#\s*Environment\s*:') {
            if (-not $seenEnvironment) {
                $cleanedLines += $line
                $seenEnvironment = $true
            }
            # Skip duplicate
        }
        else {
            $cleanedLines += $line
        }
    }
    
    # Check for existing metadata
    $hasTier = $seenTier
    $hasDependencies = $seenDependencies
    $hasEnvironment = $seenEnvironment
    
    # If we removed duplicates, update content
    if ($lines.Count -ne $cleanedLines.Count) {
        $content = $cleanedLines -join "`n"
        $needsUpdate = $true
    }
    
    $lines = $cleanedLines
    
    # Find where to insert metadata (after initial comment block)
    for ($i = 0; $i -lt [Math]::Min(20, $lines.Count); $i++) {
        if ($lines[$i] -match '^\s*#') {
            $insertIndex = $i + 1
        }
        elseif ($lines[$i] -match '^\s*$') {
            # Empty line, continue
        }
        else {
            break
        }
    }
    
    # Build metadata lines
    $metadataLines = @()
    
    if (-not $hasTier) {
        $metadataLines += "# Tier: $tier"
        $needsUpdate = $true
    }
    
    if (-not $hasDependencies -and $dependencies.Count -gt 0) {
        $depsString = $dependencies -join ', '
        $metadataLines += "# Dependencies: $depsString"
        $needsUpdate = $true
    }
    
    if (-not $hasEnvironment -and $environments.Count -gt 0) {
        $envString = $environments -join ', '
        $metadataLines += "# Environment: $envString"
        $needsUpdate = $true
    }
    
    if ($needsUpdate) {
        if ($DryRun) {
            Write-Host "Would update $($file.Name):" -ForegroundColor Yellow
            foreach ($line in $metadataLines) {
                Write-Host "  + $line" -ForegroundColor Green
            }
        }
        else {
            # Insert metadata lines
            $newLines = @()
            $newLines += $lines[0..($insertIndex - 1)]
            $newLines += $metadataLines
            $newLines += $lines[$insertIndex..($lines.Count - 1)]
            
            $newContent = $newLines -join "`n"
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
            Write-Host "Updated $($file.Name)" -ForegroundColor Green
            $updated++
            
            $fileDuration = ((Get-Date) - $fileStartTime).TotalMilliseconds
            
            # Level 2: File processing timing
            if ($debugLevel -ge 2) {
                Write-Verbose "[fragment.add-metadata] Fragment $($file.Name) processed in ${fileDuration}ms - Updated"
            }
        }
    }
    else {
        $skipped++
        
        $fileDuration = ((Get-Date) - $fileStartTime).TotalMilliseconds
        
        # Level 2: File processing timing
        if ($debugLevel -ge 2) {
            Write-Verbose "[fragment.add-metadata] Fragment $($file.Name) processed in ${fileDuration}ms - Skipped (no changes needed)"
        }
    }
    catch {
        $processErrors.Add($file.Name)
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'fragment.add-metadata' -Context @{
                fragment_name = $file.Name
                fragment_path = $file.FullName
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to process fragment $($file.Name): $($_.Exception.Message)" -IsWarning
        }
        
        # Level 2: Error details
        if ($debugLevel -ge 2) {
            Write-Verbose "[fragment.add-metadata] Fragment $($file.Name) failed with error: $($_.Exception.Message)"
        }
        
        $skipped++
    }
}

$processDuration = ((Get-Date) - $processStartTime).TotalMilliseconds

# Level 2: Overall processing timing
if ($debugLevel -ge 2) {
    Write-Verbose "[fragment.add-metadata] Processing completed in ${processDuration}ms"
    Write-Verbose "[fragment.add-metadata] Updated: $updated, Skipped: $skipped, Errors: $($processErrors.Count)"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $avgFileTime = if ($fragments.Count -gt 0) { $processDuration / $fragments.Count } else { 0 }
    Write-Host "  [fragment.add-metadata] Performance - Duration: ${processDuration}ms, Avg per file: ${avgFileTime}ms, Files: $($fragments.Count), Updated: $updated" -ForegroundColor DarkGray
}

if ($processErrors.Count -gt 0) {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        Write-StructuredWarning -Message "Some fragments failed to process" -OperationName 'fragment.add-metadata' -Context @{
            failed_fragments = $processErrors -join ','
            failed_count = $processErrors.Count
            total_fragments = $fragments.Count
        } -Code 'FragmentProcessingPartialFailure'
    }
    else {
        Write-ScriptMessage -Message "Warning: Failed to process $($processErrors.Count) fragment(s): $($processErrors -join ', ')" -IsWarning
    }
}

if ($DryRun) {
    Write-Host "`n[DRY RUN] Would update $updated fragments (skipped $skipped)" -ForegroundColor Yellow
}
else {
    Write-Host "`nUpdated $updated fragments (skipped $skipped)" -ForegroundColor Green
}
