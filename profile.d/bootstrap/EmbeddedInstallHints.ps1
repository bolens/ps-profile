# ===============================================
# EmbeddedInstallHints.ps1
# Platform-aware install commands for embedded conversion scripts
# ===============================================
# Depends on: InstallHintResolver.ps1 (Get-PreferenceAwareInstallHint)
# ===============================================

<#
.SYNOPSIS
    Helpers for resolving install hints embedded in conversion scripts and messages.

.DESCRIPTION
    Builds platform-aware npm, pip, and uv install commands and substitutes
    __NODE_INSTALL_CMD__ and __PYTHON_INSTALL_CMD__ placeholders in scripts and
    user-facing warnings.
#>

function global:Get-EmbeddedInstallCommandFromHint {
    <#
.SYNOPSIS
        Extracts the install command from a formatted install hint string.

.DESCRIPTION
        Extracts the install command from a formatted install hint string.

.PARAMETER Hint
        Hint text such as "Install with: npm install foo".

.OUTPUTS
        System.String
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowEmptyString()]
        [string]$Hint
    )

    if ([string]::IsNullOrWhiteSpace($Hint)) {
        return $null
    }

    if ($Hint -match '^Install with:\s*(.+)$') {
        return $matches[1].Trim()
    }

    return $Hint.Trim()
}

function global:Get-NodePackageInstallCommandCore {
    <#
.SYNOPSIS
        Builds an install command for one or more Node.js packages.

.DESCRIPTION
        Builds an install command for one or more Node.js packages.

.PARAMETER PackageNames
        Package names to install.

.PARAMETER Global
        Uses a global install command when preference detection falls back to npm.

.OUTPUTS
        System.String
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string[]]$PackageNames,

        [switch]$Global
    )

    $names = @($PackageNames | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($names.Count -eq 0) {
        return $null
    }

    $command = $null
    if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        $command = Get-EmbeddedInstallCommandFromHint -Hint (Get-PreferenceAwareInstallHint -ToolName $names[0] -ToolType 'node-package')
    }

    if ([string]::IsNullOrWhiteSpace($command)) {
        $command = if ($Global) {
            "npm install -g $($names[0])"
        }
        else {
            "npm install $($names[0])"
        }
    }

    if ($names.Count -eq 1) {
        return $command
    }

    if ($command -match '^(pnpm add -g|npm install -g|yarn global add|bun add -g|pnpm add|npm install|yarn add|bun add)\s+') {
        return "$($matches[1]) $($names -join ' ')"
    }

    return "$command $($names[1..($names.Count - 1)] -join ' ')"
}

function global:Get-PythonPackageInstallCommandCore {
    <#
.SYNOPSIS
        Builds an install command for one or more Python packages.

.DESCRIPTION
        Builds an install command for one or more Python packages.

.PARAMETER PackageNames
        Package names to install.

.PARAMETER Global
        Prefers uv pip install when uv is available.

.PARAMETER PythonCmd
        Python executable used for pip fallback commands.

.OUTPUTS
        System.String
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string[]]$PackageNames,

        [switch]$Global,

        [string]$PythonCmd
    )

    $names = @($PackageNames | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($names.Count -eq 0) {
        return $null
    }

    $hasUv = if (Get-Command Test-CommandAvailable -ErrorAction SilentlyContinue) {
        Test-CommandAvailable -CommandName 'uv'
    }
    else {
        (Get-Command uv -ErrorAction SilentlyContinue) -ne $null
    }

    if ($Global -and $hasUv) {
        return "uv pip install $($names -join ' ')"
    }

    $command = $null
    if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        $command = Get-EmbeddedInstallCommandFromHint -Hint (Get-PreferenceAwareInstallHint -ToolName $names[0] -ToolType 'python-package')
    }

    if ([string]::IsNullOrWhiteSpace($command)) {
        $python = if (-not [string]::IsNullOrWhiteSpace($PythonCmd)) { $PythonCmd } else { 'python' }
        $command = "$python -m pip install $($names[0])"
    }

    if ($names.Count -eq 1) {
        return $command
    }

    if ($command -match '^(uv pip install(?: --system)?|pip install|uv tool install|python(?:3)? -m pip install)\s+') {
        return "$($matches[1]) $($names -join ' ')"
    }

    if ($Global -and $hasUv) {
        return "uv pip install $($names -join ' ')"
    }

    $python = if (-not [string]::IsNullOrWhiteSpace($PythonCmd)) { $PythonCmd } else { 'python' }
    return "$python -m pip install $($names -join ' ')"
}

function global:Get-NodePackageInstallRecommendation {
    <#
.SYNOPSIS
        Gets a platform-aware install command for one or more Node.js packages.

.DESCRIPTION
        Gets a platform-aware install command for one or more Node.js packages.

.PARAMETER PackageNames
        Package names to install.

.PARAMETER PackageName
        Single package alias for PackageNames.

.PARAMETER Global
        Requests a global install command.

.OUTPUTS
        System.String
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string[]]$PackageNames,

        [string]$PackageName,

        [switch]$Global
    )

    $names = if ($PackageNames -and @($PackageNames).Count -gt 0) {
        @($PackageNames)
    }
    elseif (-not [string]::IsNullOrWhiteSpace($PackageName)) {
        @($PackageName)
    }
    else {
        @()
    }

    return Get-NodePackageInstallCommandCore -PackageNames $names -Global:$Global
}

function global:Get-PythonPackageInstallRecommendation {
    <#
.SYNOPSIS
        Gets a platform-aware install command for one or more Python packages.

.DESCRIPTION
        Gets a platform-aware install command for one or more Python packages.

.PARAMETER PackageNames
        Package names to install.

.PARAMETER PackageName
        Single package alias for PackageNames.

.PARAMETER Global
        Requests a global install command.

.PARAMETER PythonCmd
        Python executable used for pip fallback commands.

.OUTPUTS
        System.String
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string[]]$PackageNames,

        [string]$PackageName,

        [switch]$Global,

        [string]$PythonCmd
    )

    $names = if ($PackageNames -and @($PackageNames).Count -gt 0) {
        @($PackageNames)
    }
    elseif (-not [string]::IsNullOrWhiteSpace($PackageName)) {
        @($PackageName)
    }
    else {
        @()
    }

    return Get-PythonPackageInstallCommandCore -PackageNames $names -Global:$Global -PythonCmd $PythonCmd
}

function global:Expand-EmbeddedNodeInstallHints {
    <#
.SYNOPSIS
        Replaces __NODE_INSTALL_CMD__ placeholders in an embedded Node.js script.

.DESCRIPTION
        Replaces __NODE_INSTALL_CMD__ placeholders in an embedded Node.js script.

.PARAMETER Script
        Script text containing placeholders.

.PARAMETER PackageNames
        Node package names used to build the install command.

.PARAMETER Global
        Uses a global install command when building the replacement.

.OUTPUTS
        System.String
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Script,

        [Parameter(Mandatory)]
        [string[]]$PackageNames,

        [switch]$Global
    )

    $command = Get-NodePackageInstallCommandCore -PackageNames $PackageNames -Global:$Global
    if ([string]::IsNullOrWhiteSpace($command)) {
        return $Script
    }

    return $Script.Replace('__NODE_INSTALL_CMD__', $command)
}

function global:Expand-EmbeddedPythonInstallHints {
    <#
.SYNOPSIS
        Replaces __PYTHON_INSTALL_CMD__ placeholders in an embedded Python script.

.DESCRIPTION
        Replaces __PYTHON_INSTALL_CMD__ placeholders in an embedded Python script.

.PARAMETER Script
        Script text containing placeholders.

.PARAMETER PackageNames
        Python package names used to build the install command.

.PARAMETER Global
        Uses a global install command when building the replacement.

.PARAMETER PythonCmd
        Python executable used for pip fallback commands.

.OUTPUTS
        System.String
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Script,

        [Parameter(Mandatory)]
        [string[]]$PackageNames,

        [switch]$Global,

        [string]$PythonCmd
    )

    $command = Get-PythonPackageInstallCommandCore -PackageNames $PackageNames -Global:$Global -PythonCmd $PythonCmd
    if ([string]::IsNullOrWhiteSpace($command)) {
        return $Script
    }

    return $Script.Replace('__PYTHON_INSTALL_CMD__', $command)
}

function global:Resolve-NodeInstallHintMessage {
    <#
.SYNOPSIS
        Replaces __NODE_INSTALL_CMD__ placeholders in a user-facing message.

.DESCRIPTION
        Replaces __NODE_INSTALL_CMD__ placeholders in a user-facing message.

.PARAMETER Message
        Message text containing placeholders.

.PARAMETER PackageNames
        Node package names used to build the install command.

.PARAMETER Global
        Uses a global install command when building the replacement.

.OUTPUTS
        System.String
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory)]
        [string[]]$PackageNames,

        [switch]$Global
    )

    $command = Get-NodePackageInstallCommandCore -PackageNames $PackageNames -Global:$Global
    if ([string]::IsNullOrWhiteSpace($command)) {
        return $Message
    }

    return $Message.Replace('__NODE_INSTALL_CMD__', $command)
}

function global:Resolve-PythonInstallHintMessage {
    <#
.SYNOPSIS
        Replaces __PYTHON_INSTALL_CMD__ placeholders in a user-facing message.

.DESCRIPTION
        Replaces __PYTHON_INSTALL_CMD__ placeholders in a user-facing message.

.PARAMETER Message
        Message text containing placeholders.

.PARAMETER PackageNames
        Python package names used to build the install command.

.PARAMETER Global
        Uses a global install command when building the replacement.

.PARAMETER PythonCmd
        Python executable used for pip fallback commands.

.OUTPUTS
        System.String
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory)]
        [string[]]$PackageNames,

        [switch]$Global,

        [string]$PythonCmd
    )

    $command = Get-PythonPackageInstallCommandCore -PackageNames $PackageNames -Global:$Global -PythonCmd $PythonCmd
    if ([string]::IsNullOrWhiteSpace($command)) {
        return $Message
    }

    return $Message.Replace('__PYTHON_INSTALL_CMD__', $command)
}
