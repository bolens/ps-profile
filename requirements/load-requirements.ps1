# ===============================================
# Requirements Loader Script
# Loads modular requirements and returns a hashtable
# ===============================================

<#
.SYNOPSIS
    Loads modular requirements configuration.
.DESCRIPTION
    This script loads all modular requirement files and combines them into a single hashtable.
    This script loads all modular requirements files and combines them into a single hashtable.
#>

# PowerShell version requirement
$PowerShellVersion = '7.0.0'

# Get script directory (works whether script is called with & or .)
# Use the most reliable method: resolve the script's own path
# This is fully automated and doesn't require user input
$scriptPath = $null

# Try multiple methods to get script path (in order of reliability)
if ($MyInvocation.MyCommand.Path) {
    $scriptPath = $MyInvocation.MyCommand.Path
}
elseif ($PSCommandPath) {
    $scriptPath = $PSCommandPath
}
elseif ($MyInvocation.PSCommandPath) {
    $scriptPath = $MyInvocation.PSCommandPath
}
elseif ($PSScriptRoot) {
    $scriptPath = Join-Path $PSScriptRoot 'load-requirements.ps1'
}

# If we have a script path, use it
if ($scriptPath) {
    $scriptDir = Split-Path -Parent $scriptPath
    # Convert to absolute path if not already
    if (-not [System.IO.Path]::IsPathRooted($scriptDir)) {
        $scriptDir = [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $scriptDir))
    }
    else {
        $scriptDir = [System.IO.Path]::GetFullPath($scriptDir)
    }
}
else {
    # Fallback: search from current directory up to find requirements directory
    $currentPath = (Get-Location).Path
    $testPath = $currentPath
    $maxDepth = 10
    $depth = 0
    
    while ($depth -lt $maxDepth -and $testPath -and $testPath -ne (Split-Path -Parent $testPath)) {
        $testRequirementsDir = Join-Path $testPath 'requirements'
        if (Test-Path $testRequirementsDir -PathType Container) {
            $scriptDir = [System.IO.Path]::GetFullPath($testRequirementsDir)
            break
        }
        $testPath = Split-Path -Parent $testPath
        $depth++
    }
}

# Validate script directory exists
if (-not $scriptDir -or -not (Test-Path $scriptDir -PathType Container)) {
    $errorMsg = "Could not determine requirements directory. "
    $errorMsg += "Script path methods tried: MyInvocation.MyCommand.Path=$($MyInvocation.MyCommand.Path), "
    $errorMsg += "PSCommandPath=$PSCommandPath, MyInvocation.PSCommandPath=$($MyInvocation.PSCommandPath), "
    $errorMsg += "PSScriptRoot=$PSScriptRoot. Current location: $((Get-Location).Path)"
    throw $errorMsg
}

# Load PowerShell modules (automated, no user input required)
$modulesPath = Join-Path $scriptDir 'modules.psd1'
if (-not (Test-Path $modulesPath)) {
    throw "Modules file not found: $modulesPath. ScriptDir: $scriptDir"
}
try {
    $modulesConfig = Import-PowerShellDataFile $modulesPath -ErrorAction Stop
    if (-not $modulesConfig -or -not $modulesConfig.Modules) {
        throw "Invalid modules configuration in: $modulesPath"
    }
    $Modules = $modulesConfig.Modules
}
catch {
    throw "Failed to load modules from $modulesPath : $($_.Exception.Message)"
}

# Load external tools from category files
$ExternalTools = @{}

# Code Quality Tools (automated loading)
$codeQualityPath = Join-Path $scriptDir 'external-tools' 'code-quality.psd1'
if (Test-Path $codeQualityPath) {
    try {
        $codeQualityConfig = Import-PowerShellDataFile $codeQualityPath -ErrorAction Stop
        if ($codeQualityConfig.ExternalTools) {
            foreach ($tool in $codeQualityConfig.ExternalTools.Keys) {
                $ExternalTools[$tool] = $codeQualityConfig.ExternalTools[$tool]
            }
        }
    }
    catch {
        Write-Warning "Failed to load code quality tools from $codeQualityPath : $($_.Exception.Message)"
    }
}

# Container Tools (automated loading)
$containersPath = Join-Path $scriptDir 'external-tools' 'containers.psd1'
if (Test-Path $containersPath) {
    try {
        $containersConfig = Import-PowerShellDataFile $containersPath -ErrorAction Stop
        if ($containersConfig.ExternalTools) {
            foreach ($tool in $containersConfig.ExternalTools.Keys) {
                $ExternalTools[$tool] = $containersConfig.ExternalTools[$tool]
            }
        }
    }
    catch {
        Write-Warning "Failed to load container tools from $containersPath : $($_.Exception.Message)"
    }
}

# Modern CLI Tools (automated loading)
$cliToolsPath = Join-Path $scriptDir 'external-tools' 'cli-tools.psd1'
if (Test-Path $cliToolsPath) {
    try {
        $cliToolsConfig = Import-PowerShellDataFile $cliToolsPath -ErrorAction Stop
        if ($cliToolsConfig.ExternalTools) {
            foreach ($tool in $cliToolsConfig.ExternalTools.Keys) {
                $ExternalTools[$tool] = $cliToolsConfig.ExternalTools[$tool]
            }
        }
    }
    catch {
        Write-Warning "Failed to load CLI tools from $cliToolsPath : $($_.Exception.Message)"
    }
}

# Kubernetes & Cloud Tools (automated loading)
$kubernetesCloudPath = Join-Path $scriptDir 'external-tools' 'kubernetes-cloud.psd1'
if (Test-Path $kubernetesCloudPath) {
    try {
        $kubernetesCloudConfig = Import-PowerShellDataFile $kubernetesCloudPath -ErrorAction Stop
        if ($kubernetesCloudConfig.ExternalTools) {
            foreach ($tool in $kubernetesCloudConfig.ExternalTools.Keys) {
                $ExternalTools[$tool] = $kubernetesCloudConfig.ExternalTools[$tool]
            }
        }
    }
    catch {
        Write-Warning "Failed to load Kubernetes/Cloud tools from $kubernetesCloudPath : $($_.Exception.Message)"
    }
}

# Git Tools (automated loading)
$gitToolsPath = Join-Path $scriptDir 'external-tools' 'git-tools.psd1'
if (Test-Path $gitToolsPath) {
    try {
        $gitToolsConfig = Import-PowerShellDataFile $gitToolsPath -ErrorAction Stop
        if ($gitToolsConfig.ExternalTools) {
            foreach ($tool in $gitToolsConfig.ExternalTools.Keys) {
                $ExternalTools[$tool] = $gitToolsConfig.ExternalTools[$tool]
            }
        }
    }
    catch {
        Write-Warning "Failed to load Git tools from $gitToolsPath : $($_.Exception.Message)"
    }
}

# File & Data Tools (automated loading)
$fileDataPath = Join-Path $scriptDir 'external-tools' 'file-data.psd1'
if (Test-Path $fileDataPath) {
    try {
        $fileDataConfig = Import-PowerShellDataFile $fileDataPath -ErrorAction Stop
        if ($fileDataConfig.ExternalTools) {
            foreach ($tool in $fileDataConfig.ExternalTools.Keys) {
                $ExternalTools[$tool] = $fileDataConfig.ExternalTools[$tool]
            }
        }
    }
    catch {
        Write-Warning "Failed to load File/Data tools from $fileDataPath : $($_.Exception.Message)"
    }
}

# Language Runtimes & Package Managers (automated loading)
$languageRuntimesPath = Join-Path $scriptDir 'external-tools' 'language-runtimes.psd1'
if (Test-Path $languageRuntimesPath) {
    try {
        $languageRuntimesConfig = Import-PowerShellDataFile $languageRuntimesPath -ErrorAction Stop
        if ($languageRuntimesConfig.ExternalTools) {
            foreach ($tool in $languageRuntimesConfig.ExternalTools.Keys) {
                $ExternalTools[$tool] = $languageRuntimesConfig.ExternalTools[$tool]
            }
        }
    }
    catch {
        Write-Warning "Failed to load Language Runtimes tools from $languageRuntimesPath : $($_.Exception.Message)"
    }
}

# Other Tools (automated loading)
$otherToolsPath = Join-Path $scriptDir 'external-tools' 'other-tools.psd1'
if (Test-Path $otherToolsPath) {
    try {
        $otherToolsConfig = Import-PowerShellDataFile $otherToolsPath -ErrorAction Stop
        if ($otherToolsConfig.ExternalTools) {
            foreach ($tool in $otherToolsConfig.ExternalTools.Keys) {
                $ExternalTools[$tool] = $otherToolsConfig.ExternalTools[$tool]
            }
        }
    }
    catch {
        Write-Warning "Failed to load Other tools from $otherToolsPath : $($_.Exception.Message)"
    }
}

# Specialized Format Conversion Tools (automated loading)
$specializedFormatsPath = Join-Path $scriptDir 'external-tools' 'specialized-formats.psd1'
if (Test-Path $specializedFormatsPath) {
    try {
        $specializedFormatsConfig = Import-PowerShellDataFile $specializedFormatsPath -ErrorAction Stop
        if ($specializedFormatsConfig.ExternalTools) {
            foreach ($tool in $specializedFormatsConfig.ExternalTools.Keys) {
                $ExternalTools[$tool] = $specializedFormatsConfig.ExternalTools[$tool]
            }
        }
    }
    catch {
        Write-Warning "Failed to load Specialized Formats tools from $specializedFormatsPath : $($_.Exception.Message)"
    }
}

# Document Format Conversion Tools (automated loading)
$documentFormatsPath = Join-Path $scriptDir 'external-tools' 'document-formats.psd1'
if (Test-Path $documentFormatsPath) {
    try {
        $documentFormatsConfig = Import-PowerShellDataFile $documentFormatsPath -ErrorAction Stop
        if ($documentFormatsConfig.ExternalTools) {
            foreach ($tool in $documentFormatsConfig.ExternalTools.Keys) {
                $ExternalTools[$tool] = $documentFormatsConfig.ExternalTools[$tool]
            }
        }
    }
    catch {
        Write-Warning "Failed to load Document Formats tools from $documentFormatsPath : $($_.Exception.Message)"
    }
}

# Security Tools (automated loading)
$securityToolsPath = Join-Path $scriptDir 'external-tools' 'security-tools.psd1'
if (Test-Path $securityToolsPath) {
    try {
        $securityToolsConfig = Import-PowerShellDataFile $securityToolsPath -ErrorAction Stop
        if ($securityToolsConfig.ExternalTools) {
            foreach ($tool in $securityToolsConfig.ExternalTools.Keys) {
                $ExternalTools[$tool] = $securityToolsConfig.ExternalTools[$tool]
            }
        }
    }
    catch {
        Write-Warning "Failed to load Security tools from $securityToolsPath : $($_.Exception.Message)"
    }
}

# Load platform-specific requirements (automated loading)
$platformPath = Join-Path $scriptDir 'platform.psd1'
if (-not (Test-Path $platformPath)) {
    throw "Platform requirements file not found: $platformPath"
}
try {
    $platformConfig = Import-PowerShellDataFile $platformPath -ErrorAction Stop
    if (-not $platformConfig -or -not $platformConfig.PlatformRequirements) {
        throw "Invalid platform configuration in: $platformPath"
    }
    $PlatformRequirements = $platformConfig.PlatformRequirements
}
catch {
    throw "Failed to load platform requirements from $platformPath : $($_.Exception.Message)"
}

# Return combined configuration
@{
    PowerShellVersion    = $PowerShellVersion
    Modules              = $Modules
    ExternalTools        = $ExternalTools
    PlatformRequirements = $PlatformRequirements
}

