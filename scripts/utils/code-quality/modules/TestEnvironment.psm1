<#
scripts/utils/code-quality/modules/TestEnvironment.psm1

.SYNOPSIS
    Test environment detection and health check utilities for the PowerShell profile test runner.

.DESCRIPTION
    Provides functions for detecting test environment characteristics and performing
    health checks to ensure the environment is properly configured.
#>

<#
.SYNOPSIS
    Detects and returns information about the test execution environment.

.DESCRIPTION
    Identifies CI/CD environments, container environments, available tools,
    and system resources.

.OUTPUTS
    Environment information hashtable
#>
function Get-TestEnvironment {
    $env = @{
        IsCI              = $false
        CIProvider        = $null
        IsContainer       = $false
        HasDocker         = $false
        HasPodman         = $false
        HasGit            = $false
        PowerShellVersion = $PSVersionTable.PSVersion
        OS                = $PSVersionTable.OS
        Platform          = $PSVersionTable.Platform
        AvailableMemoryGB = $null
        ProcessorCount    = $env:NUMBER_OF_PROCESSORS
    }

    # Detect CI environment
    $ciVars = @('CI', 'CONTINUOUS_INTEGRATION', 'BUILD_NUMBER', 'TF_BUILD', 'GITHUB_ACTIONS', 'GITLAB_CI', 'JENKINS_HOME', 'CIRCLECI')
    foreach ($var in $ciVars) {
        if ((Get-Item "env:$var" -ErrorAction SilentlyContinue) -or (Test-Path "env:$var")) {
            $env.IsCI = $true
            break
        }
    }

    # Detect specific CI provider
    if ($env:GITHUB_ACTIONS) {
        $env.CIProvider = 'GitHub Actions'
    }
    elseif ($env:GITLAB_CI) {
        $env.CIProvider = 'GitLab CI'
    }
    elseif ($env:JENKINS_HOME) {
        $env.CIProvider = 'Jenkins'
    }
    elseif ($env:TF_BUILD) {
        $env.CIProvider = 'Azure DevOps'
    }
    elseif ($env:CIRCLECI) {
        $env.CIProvider = 'CircleCI'
    }

    # Detect container environment
    if ((Test-Path '/.dockerenv') -or $env:container -or $env:KUBERNETES_SERVICE_HOST) {
        $env.IsContainer = $true
    }

    # Check available tools
    $env.HasDocker = Get-Command 'docker' -ErrorAction SilentlyContinue
    $env.HasPodman = Get-Command 'podman' -ErrorAction SilentlyContinue
    $env.HasGit = Get-Command 'git' -ErrorAction SilentlyContinue

    # Get available memory
    try {
        $memory = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($memory) {
            $env.AvailableMemoryGB = [Math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
        }
    }
    catch {
        # Fallback for non-Windows systems
        try {
            $memInfo = Get-Content '/proc/meminfo' -ErrorAction SilentlyContinue | Where-Object { $_ -match '^MemTotal:' }
            if ($memInfo) {
                $kb = $memInfo -replace '^MemTotal:\s+(\d+).*', '$1'
                $env.AvailableMemoryGB = [Math]::Round([int]$kb / 1024 / 1024, 2)
            }
        }
        catch {
            $env.AvailableMemoryGB = 'Unknown'
        }
    }

    return $env
}

<#
.SYNOPSIS
    Performs health checks on the test environment.

.DESCRIPTION
    Validates that the test environment is properly configured and
    all required dependencies are available.

.PARAMETER CheckModules
    Check that required PowerShell modules are available.

.PARAMETER CheckPaths
    Check that required paths exist.

.PARAMETER CheckTools
    Check that required external tools are available.

.OUTPUTS
    Health check results
#>
function Test-TestEnvironmentHealth {
    param(
        [switch]$CheckModules,
        [switch]$CheckPaths,
        [switch]$CheckTools
    )

    $results = @{
        Passed = $true
        Checks = @()
    }

    if ($CheckModules) {
        $requiredModules = @('Pester')
        foreach ($module in $requiredModules) {
            $check = @{
                Name    = "Module: $module"
                Passed  = $false
                Message = $null
            }

            try {
                $installed = Get-Module -ListAvailable -Name $module -ErrorAction Stop
                if ($installed) {
                    $check.Passed = $true
                    $check.Message = "Module $module v$($installed.Version) is available"
                }
                else {
                    $check.Message = "Module $module is not installed"
                }
            }
            catch {
                $check.Message = "Failed to check module $module`: $($_.Exception.Message)"
            }

            $results.Checks += $check
            if (-not $check.Passed) {
                $results.Passed = $false
            }
        }
    }

    if ($CheckPaths) {
        $requiredPaths = @('tests', 'profile.d')
        foreach ($path in $requiredPaths) {
            $check = @{
                Name    = "Path: $path"
                Passed  = $false
                Message = $null
            }

            if (Test-Path $path) {
                $check.Passed = $true
                $check.Message = "Path $path exists"
            }
            else {
                $check.Message = "Path $path does not exist"
            }

            $results.Checks += $check
            if (-not $check.Passed) {
                $results.Passed = $false
            }
        }
    }

    if ($CheckTools) {
        $requiredTools = @('git')
        foreach ($tool in $requiredTools) {
            $check = @{
                Name    = "Tool: $tool"
                Passed  = $false
                Message = $null
            }

            if (Get-Command $tool -ErrorAction SilentlyContinue) {
                $check.Passed = $true
                $check.Message = "Tool $tool is available"
            }
            else {
                $check.Message = "Tool $tool is not available"
            }

            $results.Checks += $check
            if (-not $check.Passed) {
                $results.Passed = $false
            }
        }
    }

    return $results
}

Export-ModuleMember -Function @(
    'Get-TestEnvironment',
    'Test-TestEnvironmentHealth'
)

