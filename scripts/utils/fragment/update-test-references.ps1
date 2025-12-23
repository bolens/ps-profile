# ===============================================
# Update Test File References
# ===============================================
# Updates test files to reference new fragment names after migration
#
# Usage:
#   .\update-test-references.ps1 [-DryRun]
#
# Examples:
#   .\update-test-references.ps1 -DryRun
#   .\update-test-references.ps1

[CmdletBinding()]
param(
    [switch]$DryRun
)

# Calculate repo root manually (script is in scripts/utils/fragment/, need to go up 3 levels)
$repoRoot = $PSScriptRoot
for ($i = 1; $i -le 3; $i++) {
    $repoRoot = Split-Path -Parent $repoRoot
}

# Import ExitCodes module directly (needed for exit codes)
$exitCodesPath = Join-Path $repoRoot 'scripts' 'lib' 'core' 'ExitCodes.psm1'
if (Test-Path $exitCodesPath) {
    Import-Module $exitCodesPath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Fragment name mappings (old -> new)
$fragmentMappings = @{
    '00-bootstrap'            = 'bootstrap'
    '01-env'                  = 'env'
    '02-files'                = 'files'
    '04-scoop-completion'     = 'scoop-completion'
    '05-utilities'            = 'utilities'
    '06-oh-my-posh'           = 'oh-my-posh'
    '07-system'               = 'system'
    '08-system-info'          = 'system-info'
    '09-package-managers'     = 'package-managers'
    '10-wsl'                  = 'wsl'
    '11-git'                  = 'git'
    '12-psreadline'           = 'psreadline'
    '44-git'                  = 'git'
    '13-ansible'              = 'ansible'
    '14-ssh'                  = 'ssh'
    '15-shortcuts'            = 'shortcuts'
    '16-clipboard'            = 'clipboard'
    '17-kubectl'              = 'kubectl'
    '18-terraform'            = 'terraform'
    '19-fzf'                  = 'fzf'
    '20-gh'                   = 'gh'
    '21-kube'                 = 'kube'
    '22-containers'           = 'containers'
    '23-starship'             = 'starship'
    '30-open'                 = 'open'
    '33-aliases'              = 'aliases'
    '34-dev'                  = 'dev'
    '54-modern-cli'           = 'modern-cli'
    '55-modules'              = 'modules'
    '60-local-overrides'      = 'local-overrides'
    '61-eza'                  = 'eza'
    '62-navi'                 = 'navi'
    '63-gum'                  = 'gum'
    '64-bottom'               = 'bottom'
    '65-procs'                = 'procs'
    '66-dust'                 = 'dust'
    '25-lazydocker'           = 'lazydocker'
    '31-aws'                  = 'aws'
    '32-bun'                  = 'bun'
    '35-ollama'               = 'ollama'
    '36-ngrok'                = 'ngrok'
    '37-deno'                 = 'deno'
    '38-firebase'             = 'firebase'
    '39-rustup'               = 'rustup'
    '40-tailscale'            = 'tailscale'
    '41-yarn'                 = 'yarn'
    '42-php'                  = 'php'
    '43-laravel'              = 'laravel'
    '45-nextjs'               = 'nextjs'
    '46-vite'                 = 'vite'
    '47-angular'              = 'angular'
    '48-vue'                  = 'vue'
    '49-nuxt'                 = 'nuxt'
    '50-azure'                = 'azure'
    '51-gcloud'               = 'gcloud'
    '52-helm'                 = 'helm'
    '53-go'                   = 'go'
    '57-testing'              = 'testing'
    '58-build-tools'          = 'build-tools'
    '59-diagnostics'          = 'diagnostics'
    '67-uv'                   = 'uv'
    '68-pixi'                 = 'pixi'
    '69-pnpm'                 = 'pnpm'
    '70-profile-updates'      = 'profile-updates'
    '71-network-utils'        = 'network-utils'
    '72-error-handling'       = 'error-handling'
    '73-performance-insights' = 'performance-insights'
    '74-enhanced-history'     = 'enhanced-history'
    '75-system-monitor'       = 'system-monitor'
    '56-database'             = 'database'
    '26-rclone'               = 'rclone'
    '27-minio'                = 'minio'
    '28-jq-yq'                = 'jq-yq'
    '29-rg'                   = 'rg'
}

# Find all test files
$testsDir = Join-Path $repoRoot 'tests'
$testFiles = Get-ChildItem -Path $testsDir -Filter '*.ps1' -Recurse -File

$totalReplacements = 0
$filesUpdated = 0

foreach ($testFile in $testFiles) {
    $content = Get-Content -Path $testFile.FullName -Raw
    $originalContent = $content
    $fileReplacements = 0

    foreach ($oldName in $fragmentMappings.Keys) {
        $newName = $fragmentMappings[$oldName]
        
        # Pattern 1: '01-env.ps1' or '02-files.ps1' in paths
        $pattern1 = [regex]::Escape($oldName) + '\.ps1'
        if ($content -match $pattern1) {
            $content = $content -replace $pattern1, "$newName.ps1"
            $fileReplacements++
        }
        
        # Pattern 2: '01-env' or '02-files' in fragment names (without .ps1)
        $pattern2 = [regex]::Escape($oldName)
        # Only replace if it's not part of a larger number (e.g., don't replace '01' in '101')
        # Use word boundaries or quotes to ensure exact match
        if ($content -match "(?<![0-9])$pattern2(?![0-9])") {
            # Replace in quoted strings and comments
            $content = $content -replace "(['`"])$pattern2\1", "`$1$newName`$1"
            $content = $content -replace "#\s*$pattern2\b", "# $newName"
            $fileReplacements++
        }
    }

    if ($content -ne $originalContent) {
        $filesUpdated++
        $totalReplacements += $fileReplacements
        
        if ($DryRun) {
            Write-Host "Would update: $($testFile.FullName)" -ForegroundColor Yellow
            Write-Host "  Replacements: $fileReplacements" -ForegroundColor Gray
        }
        else {
            Set-Content -Path $testFile.FullName -Value $content -NoNewline
            Write-Host "Updated: $($testFile.FullName)" -ForegroundColor Green
            Write-Host "  Replacements: $fileReplacements" -ForegroundColor Gray
        }
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "DRY RUN: Would update $filesUpdated files with $totalReplacements replacements" -ForegroundColor Yellow
}
else {
    Write-Host "Updated $filesUpdated files with $totalReplacements replacements" -ForegroundColor Green
}

# Exit with success code
if (Get-Variable -Name 'EXIT_SUCCESS' -ErrorAction SilentlyContinue) {
    if (Get-Command -Name 'Exit-WithCode' -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode $EXIT_SUCCESS
    }
    else {
        exit $EXIT_SUCCESS
    }
}
else {
    exit 0
}

