<#
scripts/utils/fragment/sync-profile-fragments.ps1

.SYNOPSIS
    Automatically syncs .profile-fragments.json with discovered fragments and their metadata.

.DESCRIPTION
    Scans all fragments in profile.d/ and automatically updates .profile-fragments.json:
    - Discovers all fragment files
    - Parses metadata (Tier, Dependencies, Environment tags)
    - Automatically assigns fragments to environments based on:
      * Explicit # Environment: tags in fragments
      * Tier-based rules (minimal = core+essential, full = all)
      * Keyword/category matching (e.g., container fragments → containers environment)
    - Preserves manual overrides and disabled fragments
    - Updates environment lists while maintaining existing manual additions

.PARAMETER ProfileDir
    Optional. Path to the profile directory. If not provided, resolves from script location.

.PARAMETER ConfigPath
    Optional. Path to .profile-fragments.json. Defaults to ProfileDir/.profile-fragments.json.

.PARAMETER DryRun
    If set, shows what would be changed without actually modifying the file.

.PARAMETER PreserveManual
    If set, preserves manually-added fragments in environments even if they don't match auto-assignment rules.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/fragment/sync-profile-fragments.ps1

    Syncs .profile-fragments.json with all discovered fragments.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/fragment/sync-profile-fragments.ps1 -DryRun

    Shows what would be changed without modifying the file.
#>

param(
    [string]$ProfileDir,
    [string]$ConfigPath,
    [switch]$DryRun,
    [switch]$PreserveManual
)

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Resolve repo root (PSScriptRoot is scripts/utils/fragment, so go up 3 levels)
$repoRoot = $PSScriptRoot
for ($i = 1; $i -le 3; $i++) {
    $repoRoot = Split-Path -Parent $repoRoot
}

if (-not (Test-Path (Join-Path $repoRoot 'profile.d'))) {
    Write-Error "Could not resolve repository root. Please run from repository directory."
    exit 1
}

# Import required modules directly
$scriptsLibDir = Join-Path $repoRoot 'scripts' 'lib'
$fragmentLibDir = Join-Path $scriptsLibDir 'fragment'

# Import fragment modules
$fragmentConfigPath = Join-Path $fragmentLibDir 'FragmentConfig.psm1'
$fragmentLoadingPath = Join-Path $fragmentLibDir 'FragmentLoading.psm1'

if (-not (Test-Path $fragmentConfigPath)) {
    Write-Error "FragmentConfig module not found at: $fragmentConfigPath"
    exit 1
}
if (-not (Test-Path $fragmentLoadingPath)) {
    Write-Error "FragmentLoading module not found at: $fragmentLoadingPath"
    exit 1
}

Import-Module $fragmentConfigPath -DisableNameChecking -ErrorAction Stop
Import-Module $fragmentLoadingPath -DisableNameChecking -ErrorAction Stop

# Resolve paths
if (-not $ProfileDir) {
    $ProfileDir = $repoRoot
}

$profileDDir = Join-Path $ProfileDir 'profile.d'
if (-not (Test-Path -LiteralPath $profileDDir)) {
    Write-Error "profile.d directory not found: $profileDDir"
    exit 1
}

if (-not $ConfigPath) {
    $ConfigPath = Join-Path $ProfileDir '.profile-fragments.json'
}

# Load existing config
$existingConfig = @{
    disabled     = @()
    environments = @{}
    performance  = @{
        batchLoad                 = $true
        maxFragmentTime           = 500
        parallelDependencyParsing = $true
    }
}

if (Test-Path -LiteralPath $ConfigPath) {
    try {
        $configContent = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop
        if (-not [string]::IsNullOrWhiteSpace($configContent)) {
            $existingConfigObj = $configContent | ConvertFrom-Json -ErrorAction Stop
            if ($existingConfigObj.disabled) {
                $existingConfig.disabled = @($existingConfigObj.disabled)
            }
            if ($existingConfigObj.environments) {
                $existingConfigObj.environments.PSObject.Properties | ForEach-Object {
                    $existingConfig.environments[$_.Name] = @($_.Value)
                }
            }
            if ($existingConfigObj.performance) {
                $existingConfig.performance = @{
                    batchLoad                 = if ($existingConfigObj.performance.batchLoad) { $existingConfigObj.performance.batchLoad } else { $true }
                    maxFragmentTime           = if ($existingConfigObj.performance.maxFragmentTime) { $existingConfigObj.performance.maxFragmentTime } else { 500 }
                    parallelDependencyParsing = if ($existingConfigObj.performance.parallelDependencyParsing) { $existingConfigObj.performance.parallelDependencyParsing } else { $true }
                }
            }
        }
    }
    catch {
        Write-Warning "Failed to parse existing config: $($_.Exception.Message). Starting with defaults."
    }
}

# Discover all fragments
$fragmentFiles = Get-ChildItem -Path $profileDDir -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
Where-Object { $_.BaseName -notmatch '-test-' } |
Sort-Object BaseName

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[fragment.sync] Starting profile fragment synchronization"
    Write-Verbose "[fragment.sync] Profile dir: $ProfileDir, Config path: $ConfigPath"
    Write-Verbose "[fragment.sync] Dry run: $DryRun, Preserve manual: $PreserveManual"
}

Write-Host "Discovered $($fragmentFiles.Count) fragments" -ForegroundColor Cyan

# Level 2: Fragment list details
if ($debugLevel -ge 2) {
    Write-Verbose "[fragment.sync] Discovered $($fragmentFiles.Count) fragment file(s)"
}

# Parse fragment metadata
$fragmentMetadata = @{}
$parseStartTime = Get-Date
foreach ($file in $fragmentFiles) {
    # Level 1: Individual fragment parsing
    if ($debugLevel -ge 1) {
        Write-Verbose "[fragment.sync] Parsing metadata for fragment: $($file.BaseName)"
    }
    $baseName = $file.BaseName
    $metadata = @{
        Name         = $baseName
        Tier         = 'optional'
        Dependencies = @()
        Environments = @()
        Keywords     = @()
    }

    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop

        # Parse Tier
        if ($content -match '(?i)#\s*Tier\s*:\s*(core|essential|standard|optional)') {
            $metadata.Tier = $matches[1].ToLowerInvariant()
        }
        else {
            # Fallback to tier detection from FragmentLoading module
            if (Get-Command Get-FragmentTier -ErrorAction SilentlyContinue) {
                $metadata.Tier = Get-FragmentTier -FragmentFile $file
            }
        }

        # Parse Dependencies
        if ($content -match '(?i)#\s*Dependencies\s*:\s*([^\r\n]+)') {
            $depsLine = $matches[1].Trim()
            $metadata.Dependencies = @($depsLine -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }
        else {
            # Fallback to dependency detection from FragmentLoading module
            if (Get-Command Get-FragmentDependencies -ErrorAction SilentlyContinue) {
                $metadata.Dependencies = @(Get-FragmentDependencies -FragmentFile $file)
            }
        }

        # Parse explicit Environment tags (new feature)
        # Format: # Environment: minimal, development, cloud
        if ($content -match '(?i)#\s*Environment\s*:\s*([^\r\n]+)') {
            $envLine = $matches[1].Trim()
            $metadata.Environments = @($envLine -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }

        # Extract keywords from fragment name and content for category matching
        $keywords = @()
        $keywords += $baseName
        # Add common category keywords based on fragment name patterns
        if ($baseName -match 'container|docker|podman|kube|helm') { $keywords += 'containers' }
        if ($baseName -match 'aws|azure|gcloud|terraform|cloud') { $keywords += 'cloud' }
        if ($baseName -match 'git|gh') { $keywords += 'git' }
        if ($baseName -match 'npm|pnpm|yarn|bun|package') { $keywords += 'web' }
        if ($baseName -match 'go|rust|python|java|php|deno|dart|swift|julia|dotnet') { $keywords += 'development' }
        if ($baseName -match 'database|sql|postgres|mysql') { $keywords += 'server' }
        if ($baseName -match 'network|ssh|security') { $keywords += 'server' }
        $metadata.Keywords = $keywords
    }
    catch {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to parse fragment metadata" -OperationName 'fragment.sync.metadata' -Context @{
                fragment_name = $baseName
                fragment_path = $file.FullName
            } -Code 'FragmentMetadataParseFailed'
        }
        else {
            Write-Warning "Failed to parse metadata for $baseName : $($_.Exception.Message)"
        }
    }

    $fragmentMetadata[$baseName] = $metadata
}

$parseDuration = ((Get-Date) - $parseStartTime).TotalMilliseconds

# Level 2: Metadata parsing timing
if ($debugLevel -ge 2) {
    Write-Verbose "[fragment.sync] Metadata parsing completed in ${parseDuration}ms"
    Write-Verbose "[fragment.sync] Fragments parsed: $($fragmentMetadata.Keys.Count)"
}

# Level 1: Environment assignment start
if ($debugLevel -ge 1) {
    Write-Verbose "[fragment.sync] Starting environment assignment"
}

# Define environment assignment rules
function Get-EnvironmentAssignments {
    param(
        [hashtable]$Metadata,
        [hashtable]$ExistingEnvironments
    )

    $assignments = @{}

    # Get all existing environment names
    $envNames = @('minimal', 'testing', 'ci', 'server', 'cloud', 'containers', 'web', 'development', 'full')
    foreach ($envName in $envNames) {
        $assignments[$envName] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    # Preserve manually-added fragments if requested
    if ($PreserveManual) {
        foreach ($envName in $envNames) {
            if ($ExistingEnvironments.ContainsKey($envName)) {
                foreach ($fragment in $ExistingEnvironments[$envName]) {
                    [void]$assignments[$envName].Add($fragment)
                }
            }
        }
    }

    # Process each fragment
    foreach ($fragmentName in $Metadata.Keys) {
        $meta = $Metadata[$fragmentName]

        # 1. Explicit environment tags take highest priority
        if ($meta.Environments.Count -gt 0) {
            foreach ($env in $meta.Environments) {
                if ($assignments.ContainsKey($env)) {
                    [void]$assignments[$env].Add($fragmentName)
                }
            }
            continue
        }

        # 2. Tier-based assignments
        $tier = $meta.Tier

        # minimal: core + essential
        if ($tier -in @('core', 'essential')) {
            [void]$assignments['minimal'].Add($fragmentName)
        }

        # testing: core + essential + standard (testing-related)
        if ($tier -in @('core', 'essential', 'standard')) {
            if ($fragmentName -match 'test|diagnostic|error') {
                [void]$assignments['testing'].Add($fragmentName)
            }
        }

        # ci: core + essential + standard (CI-related, no interactive tools)
        if ($tier -in @('core', 'essential', 'standard')) {
            if ($fragmentName -notmatch 'oh-my-posh|starship|psreadline|interactive|prompt') {
                [void]$assignments['ci'].Add($fragmentName)
            }
        }

        # server: core + essential + standard (server-focused)
        if ($tier -in @('core', 'essential', 'standard')) {
            if ($fragmentName -match 'server|system|database|network|ssh|security|monitor|info') {
                [void]$assignments['server'].Add($fragmentName)
            }
        }

        # cloud: cloud-related fragments
        if ($meta.Keywords -contains 'cloud' -or $fragmentName -match 'aws|azure|gcloud|terraform|kubectl|kube|helm|cloud') {
            [void]$assignments['cloud'].Add($fragmentName)
        }

        # containers: container-related fragments
        if ($meta.Keywords -contains 'containers' -or $fragmentName -match 'container|docker|podman|kube|helm|lazydocker|minio') {
            [void]$assignments['containers'].Add($fragmentName)
        }

        # web: web development fragments
        if ($meta.Keywords -contains 'web' -or $fragmentName -match 'npm|pnpm|yarn|bun|package|build|dev|api|open|ngrok|angular|nextjs|nuxt|vue|vite|laravel|firebase') {
            [void]$assignments['web'].Add($fragmentName)
        }

        # development: all development tools
        if ($meta.Keywords -contains 'development' -or $tier -in @('core', 'essential', 'standard') -or $fragmentName -match 'git|go|rust|python|java|php|deno|dart|swift|julia|dotnet|lang-|build|test|dev|modern-cli|modules|database|diagnostic|eza|navi|gum|bottom|procs|dust|jq-yq|rg|fzf|open|gh|aliases|shortcuts|clipboard|scoop|mise|asdf|volta|homebrew|chocolatey|winget|nuget|vcpkg|conan|cocoapods|gem|nimble|mix|rustup|conda|pixi|gradle|maven|testing|build-tools|diagnostics|error-handling') {
            [void]$assignments['development'].Add($fragmentName)
        }

        # full: everything
        [void]$assignments['full'].Add($fragmentName)
    }

    # Ensure bootstrap and env are always in minimal environments
    foreach ($envName in @('minimal', 'testing', 'ci', 'server', 'cloud', 'containers', 'web', 'development', 'full')) {
        [void]$assignments[$envName].Add('bootstrap')
        [void]$assignments[$envName].Add('env')
    }

    # Convert HashSets to sorted arrays
    $result = @{}
    foreach ($envName in $assignments.Keys) {
        $result[$envName] = @($assignments[$envName] | Sort-Object)
    }

    return $result
}

# Level 1: Environment assignment execution
if ($debugLevel -ge 1) {
    Write-Verbose "[fragment.sync] Generating environment assignments"
}

# Generate new environment assignments
$assignStartTime = Get-Date
$newEnvironments = Get-EnvironmentAssignments -Metadata $fragmentMetadata -ExistingEnvironments $existingConfig.environments
$assignDuration = ((Get-Date) - $assignStartTime).TotalMilliseconds

# Level 2: Environment assignment timing
if ($debugLevel -ge 2) {
    Write-Verbose "[fragment.sync] Environment assignment completed in ${assignDuration}ms"
    $totalFragments = ($newEnvironments.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    Write-Verbose "[fragment.sync] Total fragment assignments: $totalFragments"
}

# Level 1: Config building start
if ($debugLevel -ge 1) {
    Write-Verbose "[fragment.sync] Building new configuration"
}

# Build new config
$newConfig = @{
    disabled     = $existingConfig.disabled
    environments = $newEnvironments
    performance  = $existingConfig.performance
}

# Convert to JSON with proper formatting
$jsonContent = $newConfig | ConvertTo-Json -Depth 10

# Show changes
Write-Host "`nEnvironment assignments:" -ForegroundColor Cyan
Write-Host "  full : (auto-loads all fragments, no list maintained)" -ForegroundColor Gray
foreach ($envName in ($newEnvironments.Keys | Sort-Object)) {
    $fragments = $newEnvironments[$envName]
    Write-Host "  $envName : $($fragments.Count) fragments" -ForegroundColor Gray
    if ($DryRun -and $existingConfig.environments.ContainsKey($envName)) {
        $oldFragments = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($f in $existingConfig.environments[$envName]) {
            [void]$oldFragments.Add($f)
        }
        $newFragments = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($f in $fragments) {
            [void]$newFragments.Add($f)
        }
        $added = @($newFragments | Where-Object { -not $oldFragments.Contains($_) })
        $removed = @($oldFragments | Where-Object { -not $newFragments.Contains($_) })
        if ($added.Count -gt 0) {
            Write-Host "    + Added: $($added -join ', ')" -ForegroundColor Green
        }
        if ($removed.Count -gt 0) {
            Write-Host "    - Removed: $($removed -join ', ')" -ForegroundColor Yellow
        }
    }
}
if ($DryRun -and $existingConfig.environments.ContainsKey('full')) {
    Write-Host "  full will be removed from config (auto-loads all fragments)" -ForegroundColor Yellow
}

if ($DryRun) {
    Write-Host "`n[DRY RUN] Would update $ConfigPath" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes." -ForegroundColor Yellow
    exit 0
}

# Write updated config
try {
    # Level 1: Config save start
    if ($debugLevel -ge 1) {
        Write-Verbose "[fragment.sync] Saving updated configuration to: $ConfigPath"
    }
    
    # Format JSON nicely
    $saveStartTime = Get-Date
    $formattedJson = ($jsonContent | ConvertFrom-Json | ConvertTo-Json -Depth 10)
    Set-Content -Path $ConfigPath -Value $formattedJson -Encoding UTF8 -ErrorAction Stop
    $saveDuration = ((Get-Date) - $saveStartTime).TotalMilliseconds
    
    # Level 2: Config save timing
    if ($debugLevel -ge 2) {
        Write-Verbose "[fragment.sync] Configuration saved in ${saveDuration}ms"
    }
    
    # Level 3: Performance breakdown
    if ($debugLevel -ge 3) {
        $totalDuration = $parseDuration + $assignDuration + $saveDuration
        Write-Host "  [fragment.sync] Performance - Parse: ${parseDuration}ms, Assign: ${assignDuration}ms, Save: ${saveDuration}ms, Total: ${totalDuration}ms" -ForegroundColor DarkGray
    }
    
    Write-Host "`n✓ Updated $ConfigPath" -ForegroundColor Green
    exit 0
}
catch {
    Write-Error "Failed to write config: $($_.Exception.Message)"
    exit 1
}
