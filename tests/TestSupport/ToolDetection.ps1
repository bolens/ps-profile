<#
.SYNOPSIS
    Tool detection and recommendation utilities for tests.

.DESCRIPTION
    Provides functions to detect tool availability, recommend installation commands,
    and gracefully skip tests when optional tools are missing.

.NOTES
    This module is part of the TestSupport utilities and should be imported via TestSupport.ps1
#>

function Test-ToolAvailable {
    <#
    .SYNOPSIS
        Checks if a tool is available in the PATH.

    .DESCRIPTION
        Tests whether a command/tool is available and optionally provides installation
        recommendations if the tool is missing.

    .PARAMETER ToolName
        Name of the tool/command to check.

    .PARAMETER InstallCommand
        Recommended installation command (e.g., 'scoop install docker').

    .PARAMETER InstallUrl
        URL where the tool can be downloaded.

    .PARAMETER Required
        If specified, throws an error when the tool is not available.

    .PARAMETER Silent
        If specified, suppresses warning messages for missing optional tools.

    .EXAMPLE
        $result = Test-ToolAvailable -ToolName 'docker' -InstallCommand 'scoop install docker'
        if ($result.Available) {
            # Use docker
        }

    .OUTPUTS
        PSCustomObject with properties:
        - Name: Tool name
        - Available: Boolean indicating if tool is available
        - Path: Full path to tool if available, null otherwise
        - Required: Whether tool is required
        - InstallCommand: Recommended installation command
        - InstallUrl: Download URL
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,

        [string]$InstallCommand,

        [string]$InstallUrl,

        [switch]$Required,

        [switch]$Silent
    )

    $available = Get-Command $ToolName -ErrorAction SilentlyContinue

    if (-not $available -and $Required) {
        $message = "Required tool '$ToolName' is not available."
        if ($InstallCommand) {
            $message += " Install with: $InstallCommand"
        }
        if ($InstallUrl) {
            $message += " Download from: $InstallUrl"
        }
        throw $message
    }

    if (-not $available -and -not $Silent) {
        $warningMessage = "Optional tool '$ToolName' is not available."
        if ($InstallCommand) {
            $warningMessage += " Install with: $InstallCommand"
        }
        if ($InstallUrl) {
            $warningMessage += " Download from: $InstallUrl"
        }
        Write-Warning $warningMessage
    }

    return [PSCustomObject]@{
        Name           = $ToolName
        Available      = [bool]$available
        Path           = if ($available) { $available.Source } else { $null }
        Required       = $Required.IsPresent
        InstallCommand = $InstallCommand
        InstallUrl     = $InstallUrl
    }
}

function Get-ToolRecommendations {
    <#
    .SYNOPSIS
        Gets recommendations for common development tools.

    .DESCRIPTION
        Checks availability of common development tools and provides installation
        recommendations for missing tools. Uses preference-aware install hints
        when available.

    .PARAMETER Silent
        If specified, suppresses warning messages.

    .EXAMPLE
        $tools = Get-ToolRecommendations
        $missingTools = $tools | Where-Object { -not $_.Available }
        if ($missingTools) {
            Write-Host "Missing tools: $($missingTools.Name -join ', ')"
        }

    .OUTPUTS
        Array of PSCustomObject with tool information (see Test-ToolAvailable output).
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [switch]$Silent
    )

    # Try to load preference-aware install hint function
    $usePreferenceAware = $false
    if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        $usePreferenceAware = $true
    }

    $tools = @(
        @{
            Name           = 'docker'
            InstallCommand = 'scoop install docker'
            InstallUrl     = 'https://www.docker.com/get-started'
            ToolType       = 'generic'
        }
        @{
            Name           = 'podman'
            InstallCommand = 'scoop install podman'
            InstallUrl     = 'https://podman.io/getting-started/installation'
            ToolType       = 'generic'
        }
        @{
            Name           = 'git'
            InstallCommand = 'scoop install git'
            InstallUrl     = 'https://git-scm.com/downloads'
            ToolType       = 'generic'
        }
        @{
            Name           = 'kubectl'
            InstallCommand = 'scoop install kubectl'
            InstallUrl     = 'https://kubernetes.io/docs/tasks/tools/'
            ToolType       = 'generic'
        }
        @{
            Name           = 'terraform'
            InstallCommand = 'scoop install terraform'
            InstallUrl     = 'https://www.terraform.io/downloads'
            ToolType       = 'generic'
        }
        @{
            Name           = 'aws'
            InstallCommand = 'scoop install aws'
            InstallUrl     = 'https://aws.amazon.com/cli/'
            ToolType       = 'generic'
        }
        @{
            Name           = 'az'
            InstallCommand = 'scoop install azure-cli'
            InstallUrl     = 'https://docs.microsoft.com/en-us/cli/azure/install-azure-cli'
            ToolType       = 'generic'
        }
        @{
            Name           = 'gcloud'
            InstallCommand = 'scoop install gcloud'
            InstallUrl     = 'https://cloud.google.com/sdk/docs/install'
            ToolType       = 'generic'
        }
        @{
            Name           = 'oh-my-posh'
            InstallCommand = 'scoop install oh-my-posh'
            InstallUrl     = 'https://ohmyposh.dev/docs/installation'
            ToolType       = 'generic'
        }
        @{
            Name           = 'starship'
            InstallCommand = 'scoop install starship'
            InstallUrl     = 'https://starship.rs/guide/#%F0%9F%9A%80-installation'
            ToolType       = 'generic'
        }
        @{
            Name           = 'bat'
            InstallCommand = 'scoop install bat'
            InstallUrl     = 'https://github.com/sharkdp/bat'
            ToolType       = 'generic'
        }
        @{
            Name           = 'fd'
            InstallCommand = 'scoop install fd'
            InstallUrl     = 'https://github.com/sharkdp/fd'
            ToolType       = 'generic'
        }
        @{
            Name           = 'http'
            InstallCommand = 'scoop install httpie'
            InstallUrl     = 'https://httpie.io/'
            ToolType       = 'generic'
        }
        @{
            Name           = 'zoxide'
            InstallCommand = 'scoop install zoxide'
            InstallUrl     = 'https://github.com/ajeetdsouza/zoxide'
            ToolType       = 'generic'
        }
        @{
            Name           = 'delta'
            InstallCommand = 'scoop install delta'
            InstallUrl     = 'https://github.com/dandavison/delta'
            ToolType       = 'generic'
        }
        @{
            Name           = 'tldr'
            InstallCommand = 'scoop install tldr'
            InstallUrl     = 'https://tldr.sh/'
            ToolType       = 'generic'
        }
        @{
            Name           = 'procs'
            InstallCommand = 'scoop install procs'
            InstallUrl     = 'https://github.com/dalance/procs'
            ToolType       = 'generic'
        }
        @{
            Name           = 'dust'
            InstallCommand = 'scoop install dust'
            InstallUrl     = 'https://github.com/bootandy/dust'
            ToolType       = 'generic'
        }
        @{
            Name           = 'ssh'
            InstallCommand = 'scoop install openssh'
            InstallUrl     = 'https://www.openssh.com/'
            ToolType       = 'generic'
        }
        @{
            Name           = 'ansible'
            InstallCommand = 'pip install ansible'
            InstallUrl     = 'https://docs.ansible.com/ansible/latest/installation_guide/index.html'
            ToolType       = 'python-package'
        }
        @{
            Name           = 'gh'
            InstallCommand = 'scoop install gh'
            InstallUrl     = 'https://cli.github.com/'
            ToolType       = 'generic'
        }
        @{
            Name           = 'wsl'
            InstallCommand = 'wsl --install'
            InstallUrl     = 'https://docs.microsoft.com/en-us/windows/wsl/install'
            ToolType       = 'generic'
        }
        @{
            Name           = 'pnpm'
            InstallCommand = 'npm install -g pnpm'
            InstallUrl     = 'https://pnpm.io/installation'
            ToolType       = 'node-package'
        }
        @{
            Name           = 'uv'
            InstallCommand = 'pip install uv'
            InstallUrl     = 'https://github.com/astral-sh/uv'
            ToolType       = 'python-package'
        }
    )

    $results = @()
    foreach ($tool in $tools) {
        # Use preference-aware install hint if available
        $installCommand = $tool.InstallCommand
        if ($usePreferenceAware) {
            try {
                $hint = Get-PreferenceAwareInstallHint -ToolName $tool.Name -ToolType $tool.ToolType -DefaultInstallCommand $tool.InstallCommand
                # Extract command from hint (remove "Install with: " prefix if present)
                if ($hint -match '^Install with:\s*(.+)$') {
                    $installCommand = $matches[1]
                }
                elseif ($hint -and -not ($hint -match '^Install with:')) {
                    $installCommand = $hint
                }
            }
            catch {
                # Fall back to default if preference-aware hint fails
                $installCommand = $tool.InstallCommand
            }
        }
        
        $result = Test-ToolAvailable `
            -ToolName $tool.Name `
            -InstallCommand $installCommand `
            -InstallUrl $tool.InstallUrl `
            -Silent:$Silent.IsPresent
        $results += $result
    }

    return $results
}

function Get-MissingTools {
    <#
    .SYNOPSIS
        Gets list of missing tools from recommendations.

    .DESCRIPTION
        Returns only the tools that are not available from the standard
        tool recommendations.

    .PARAMETER Silent
        If specified, suppresses warning messages.

    .EXAMPLE
        $missing = Get-MissingTools
        if ($missing) {
            Write-Host "Please install: $($missing.Name -join ', ')"
        }

    .OUTPUTS
        Array of PSCustomObject with tool information for missing tools.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [switch]$Silent
    )

    $allTools = Get-ToolRecommendations -Silent:$Silent.IsPresent
    return $allTools | Where-Object { -not $_.Available }
}

function Show-ToolRecommendations {
    <#
    .SYNOPSIS
        Displays tool recommendations in a formatted table.

    .DESCRIPTION
        Shows all tool recommendations with their availability status and
        installation instructions.

    .PARAMETER MissingOnly
        If specified, only shows missing tools.

    .EXAMPLE
        Show-ToolRecommendations
        Show-ToolRecommendations -MissingOnly

    .OUTPUTS
        None. Outputs formatted table to console.
    #>
    [CmdletBinding()]
    param(
        [switch]$MissingOnly
    )

    $tools = Get-ToolRecommendations -Silent
    if ($MissingOnly) {
        $tools = $tools | Where-Object { -not $_.Available }
    }

    if (-not $tools) {
        Write-Host "No tools to display." -ForegroundColor Green
        return
    }

    $tools | Format-Table -Property Name, Available, InstallCommand, InstallUrl -AutoSize

    $missingCount = ($tools | Where-Object { -not $_.Available }).Count
    if ($missingCount -gt 0) {
        Write-Host "`n$missingCount tool(s) are not available. Install them using the commands above." -ForegroundColor Yellow
    }
}

# Functions are available in the current scope when dot-sourced
# No Export-ModuleMember needed since this is dot-sourced, not imported as a module

