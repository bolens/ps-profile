<#
scripts/lib/utilities/RequirementsList.psm1

.SYNOPSIS
    Parses root-level requirements list files (Python, Scoop, Linux distro sections).

.DESCRIPTION
    Loads package names from requirements.txt (repo root), requirements/scoop.txt,
    and requirements/linux.txt (apt, pacman, dnf sections). Used by dependency
    validation scripts and tests.
#>

function Get-RequirementsManifestPath {
    <#
    .SYNOPSIS
        Resolves canonical paths for install manifest files.

    .DESCRIPTION
        Maps logical manifest kinds to repository-relative paths used by dependency
        validation scripts.

    .PARAMETER RepoRoot
        Repository root directory.

    .PARAMETER Kind
        python - requirements.txt at repo root; scoop - requirements/scoop.txt;
        linux - requirements/linux.txt.

    .OUTPUTS
        System.String

    .EXAMPLE
        Get-RequirementsManifestPath -RepoRoot $repoRoot -Kind 'python'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$RepoRoot,

        [Parameter(Mandatory)]
        [ValidateSet('python', 'scoop', 'linux')]
        [string]$Kind
    )

    switch ($Kind) {
        'python' { return Join-Path $RepoRoot 'requirements.txt' }
        'scoop' { return Join-Path $RepoRoot 'requirements' 'scoop.txt' }
        'linux' { return Join-Path $RepoRoot 'requirements' 'linux.txt' }
    }
}

function Get-RequirementsListFromFile {
    <#
    .SYNOPSIS
        Reads plain package names from a requirements list file (one per line).

    .DESCRIPTION
        Skips blank lines, comments, and section header markers.

    .PARAMETER Path
        Requirements list file to parse.

    .OUTPUTS
        System.String[]

    .EXAMPLE
        Get-RequirementsListFromFile -Path $manifestPath
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


.DESCRIPTION
    Parses package names from requirements.txt (strips version specifiers).

    .PARAMETER Path
        requirements.txt file path.


    .PARAMETER Path
    requirements.txt file path.

    .OUTPUTS
        System.String[]


    .OUTPUTS
    System.String[]

    .EXAMPLE

    .EXAMPLE
        Get-PythonRequirementsFromFile -Path (Join-Path $repoRoot 'requirements.txt')
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
        Parses a distro section from requirements/linux.txt.


.DESCRIPTION
    Parses a distro section from requirements/linux.txt.

    .PARAMETER Path
        Path to requirements/linux.txt.


    .PARAMETER Section
        apt, pacman, or dnf (matches # --- section headers).


    .PARAMETER Path
    Path to requirements/linux.txt.

    .PARAMETER Section
    apt, pacman, or dnf (matches # --- section headers).

    .OUTPUTS
        System.String[]


    .OUTPUTS
    System.String[]

    .EXAMPLE

    .EXAMPLE
        Get-LinuxRequirementsFromFile -Path $linuxManifest -Section 'apt'
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


.DESCRIPTION
    Returns dependency package names from package.json.

    .PARAMETER Path
        package.json file path.


    .PARAMETER Path
    package.json file path.

    .OUTPUTS
        System.String[]


    .OUTPUTS
    System.String[]

    .EXAMPLE

    .EXAMPLE
        Get-NpmRequirementsFromPackageJson -Path (Join-Path $repoRoot 'package.json')
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
.DESCRIPTION
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


.DESCRIPTION
    Loads system package names for the detected or specified package manager.

    .PARAMETER RepoRoot
        Repository root containing requirements manifests.


    .PARAMETER PackageManager
        Optional package manager override (scoop, apt, pacman, dnf).


    .PARAMETER RepoRoot
    Repository root containing requirements manifests.

    .PARAMETER PackageManager
    Optional package manager override (scoop, apt, pacman, dnf).

    .OUTPUTS
        System.String[]


    .OUTPUTS
    System.String[]

    .EXAMPLE

    .EXAMPLE
        Get-SystemRequirementsPackages -RepoRoot $repoRoot
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
            $path = Get-RequirementsManifestPath -RepoRoot $RepoRoot -Kind 'scoop'
            return Get-RequirementsListFromFile -Path $path
        }
        { $_ -in 'apt', 'pacman', 'dnf' } {
            $path = Get-RequirementsManifestPath -RepoRoot $RepoRoot -Kind 'linux'
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


.DESCRIPTION
    Builds a bulk install command for missing system packages.

    .PARAMETER PackageNames
        Package names to install.


    .PARAMETER PackageManager
        Target package manager (scoop, apt, pacman, dnf).


    .PARAMETER PackageNames
    Package names to install.

    .PARAMETER PackageManager
    Target package manager (scoop, apt, pacman, dnf).

    .OUTPUTS
        System.String


    .OUTPUTS
    System.String

    .EXAMPLE

    .EXAMPLE
        Get-SystemPackageInstallCommand -PackageNames 'git','jq' -PackageManager 'apt'
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
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
    'Get-RequirementsManifestPath'
    'Get-RequirementsListFromFile'
    'Get-PythonRequirementsFromFile'
    'Get-LinuxRequirementsFromFile'
    'Get-NpmRequirementsFromPackageJson'
    'Get-SystemPackageManagerKind'
    'Get-SystemRequirementsPackages'
    'Get-SystemPackageInstallCommand'
)
