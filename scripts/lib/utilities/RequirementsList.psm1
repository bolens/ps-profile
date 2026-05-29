<#
scripts/lib/utilities/RequirementsList.psm1

.SYNOPSIS
    Parses root-level requirements list files (Python, Scoop, Linux distro sections).

.DESCRIPTION
    Loads package names from requirements.txt, requirements-scoop.txt, and
    requirements-linux.txt (apt, pacman, dnf sections). Used by dependency
    validation scripts and tests.
#>

function Get-RequirementsListFromFile {
    <#
    .SYNOPSIS
        Reads plain package names from a requirements list file (one per line).
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Requirements file not found: $Path"
    }

    $packages = [System.Collections.Generic.List[string]]::new()
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
            continue
        }
        if ($trimmed -match '^# ---') {
            continue
        }
        $packages.Add($trimmed)
    }

    return @($packages | Select-Object -Unique)
}

function Get-PythonRequirementsFromFile {
    <#
    .SYNOPSIS
        Parses package names from requirements.txt (strips version specifiers).
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Requirements file not found: $Path"
    }

    $packages = [System.Collections.Generic.List[string]]::new()
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
            continue
        }
        if ($trimmed -match '^([A-Za-z0-9][A-Za-z0-9._-]*)') {
            $packages.Add($Matches[1])
        }
    }

    return @($packages | Select-Object -Unique)
}

function Get-LinuxRequirementsFromFile {
    <#
    .SYNOPSIS
        Parses a distro section from requirements-linux.txt.
    .PARAMETER Section
        apt, pacman, or dnf (matches # --- section headers).
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateSet('apt', 'pacman', 'dnf')]
        [string]$Section
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Requirements file not found: $Path"
    }

    $sectionPattern = "# --- $Section"
    $inSection = $false
    $packages = [System.Collections.Generic.List[string]]::new()

    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^# --- ') {
            $inSection = $trimmed.StartsWith($sectionPattern, [System.StringComparison]::OrdinalIgnoreCase)
            continue
        }

        if (-not $inSection) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
            continue
        }

        $packages.Add($trimmed)
    }

    return @($packages | Select-Object -Unique)
}

function Get-NpmRequirementsFromPackageJson {
    <#
    .SYNOPSIS
        Returns dependency package names from package.json.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "package.json not found: $Path"
    }

    $json = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    $names = [System.Collections.Generic.List[string]]::new()

    if ($json.dependencies) {
        foreach ($key in $json.dependencies.PSObject.Properties.Name) {
            $names.Add([string]$key)
        }
    }

    return @($names | Select-Object -Unique)
}

function Get-SystemPackageManagerKind {
    <#
    .SYNOPSIS
        Detects the preferred system package manager for the current platform.
    .OUTPUTS
        scoop, apt, pacman, dnf, brew, or $null if unknown.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $preference = if ($env:PS_SYSTEM_PACKAGE_MANAGER) {
        $env:PS_SYSTEM_PACKAGE_MANAGER.Trim().ToLower()
    }
    else {
        'auto'
    }

    $candidates = if ($preference -ne 'auto') {
        @($preference)
    }
    elseif ($IsWindows -or ($PSVersionTable.PSVersion.Major -lt 6 -and -not $IsLinux -and -not $IsMacOS)) {
        @('scoop', 'winget', 'choco')
    }
    elseif ($IsMacOS) {
        @('brew')
    }
    else {
        @('pacman', 'apt', 'dnf', 'zypper', 'brew')
    }

    foreach ($kind in $candidates) {
        switch ($kind) {
            'scoop' {
                if (Get-Command scoop -ErrorAction SilentlyContinue) { return 'scoop' }
            }
            'apt' {
                if (Get-Command apt-get -ErrorAction SilentlyContinue) { return 'apt' }
                if (Get-Command apt -ErrorAction SilentlyContinue) { return 'apt' }
            }
            'pacman' {
                if (Get-Command pacman -ErrorAction SilentlyContinue) { return 'pacman' }
            }
            'dnf' {
                if (Get-Command dnf -ErrorAction SilentlyContinue) { return 'dnf' }
            }
            'yum' {
                if (Get-Command yum -ErrorAction SilentlyContinue) { return 'dnf' }
            }
            'zypper' {
                if (Get-Command zypper -ErrorAction SilentlyContinue) { return 'zypper' }
            }
            'brew' {
                if (Get-Command brew -ErrorAction SilentlyContinue) { return 'brew' }
            }
            'winget' {
                if (Get-Command winget -ErrorAction SilentlyContinue) { return 'winget' }
            }
            'choco' {
                if (Get-Command choco -ErrorAction SilentlyContinue) { return 'choco' }
            }
        }
    }

    return $null
}

function Get-SystemRequirementsPackages {
    <#
    .SYNOPSIS
        Loads system package names for the detected or specified package manager.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$RepoRoot,

        [string]$PackageManager
    )

    $pm = if ($PackageManager) { $PackageManager.ToLower() } else { Get-SystemPackageManagerKind }

    switch ($pm) {
        'scoop' {
            $path = Join-Path $RepoRoot 'requirements-scoop.txt'
            return Get-RequirementsListFromFile -Path $path
        }
        { $_ -in 'apt', 'pacman', 'dnf' } {
            $path = Join-Path $RepoRoot 'requirements-linux.txt'
            return Get-LinuxRequirementsFromFile -Path $path -Section $pm
        }
        default {
            return @()
        }
    }
}

function Get-SystemPackageInstallCommand {
    <#
    .SYNOPSIS
        Builds a bulk install command for missing system packages.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string[]]$PackageNames,

        [Parameter(Mandatory)]
        [ValidateSet('scoop', 'apt', 'pacman', 'dnf')]
        [string]$PackageManager
    )

    if ($PackageNames.Count -eq 0) {
        return ''
    }

    $list = $PackageNames -join ' '
    switch ($PackageManager) {
        'scoop' { return "scoop install $list" }
        'apt' { return "sudo apt install -y $list" }
        'pacman' { return "sudo pacman -S --needed $list" }
        'dnf' { return "sudo dnf install -y $list" }
        default { return "<package-manager> install $list" }
    }
}

Export-ModuleMember -Function @(
    'Get-RequirementsListFromFile'
    'Get-PythonRequirementsFromFile'
    'Get-LinuxRequirementsFromFile'
    'Get-NpmRequirementsFromPackageJson'
    'Get-SystemPackageManagerKind'
    'Get-SystemRequirementsPackages'
    'Get-SystemPackageInstallCommand'
)
