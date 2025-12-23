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

foreach ($file in $fragments) {
    $baseName = $file.BaseName
    $content = Get-Content -Path $file.FullName -Raw
    
    if ([string]::IsNullOrWhiteSpace($content)) {
        Write-Warning "Skipping empty file: $($file.Name)"
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
        }
    }
    else {
        $skipped++
    }
}

if ($DryRun) {
    Write-Host "`n[DRY RUN] Would update $updated fragments (skipped $skipped)" -ForegroundColor Yellow
}
else {
    Write-Host "`nUpdated $updated fragments (skipped $skipped)" -ForegroundColor Green
}
