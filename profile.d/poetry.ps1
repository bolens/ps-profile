# ===============================================
# poetry.ps1
# Poetry Python dependency management
# ===============================================

# Poetry aliases and functions
# Requires: poetry (https://python-poetry.org/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand poetry) {
    # Poetry install
    <#
    .SYNOPSIS
        Installs Poetry project dependencies.
    .DESCRIPTION
        Installs dependencies defined in pyproject.toml and poetry.lock.
    #>
    function Install-PoetryDependencies {
        [CmdletBinding()]
        param()
        
        & poetry install @args
    }
    Set-Alias -Name poetry-install -Value Install-PoetryDependencies -ErrorAction SilentlyContinue

    # Poetry add
    <#
    .SYNOPSIS
        Adds dependencies to Poetry project.
    .DESCRIPTION
        Adds packages as dependencies to pyproject.toml. Supports --group dev, --group test, --group docs flags.
    .PARAMETER Packages
        Package names to add.
    .PARAMETER Dev
        Add as dev dependency (--group dev).
    .PARAMETER Test
        Add as test dependency (--group test).
    .PARAMETER Docs
        Add as docs dependency (--group docs).
    .PARAMETER Optional
        Add as optional dependency (--optional).
    .EXAMPLE
        Add-PoetryDependency requests
        Adds requests as a production dependency.
    .EXAMPLE
        Add-PoetryDependency pytest -Dev
        Adds pytest as a dev dependency.
    .EXAMPLE
        Add-PoetryDependency sphinx -Docs
        Adds sphinx as a docs dependency.
    #>
    function Add-PoetryDependency {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Dev,
            [switch]$Test,
            [switch]$Docs,
            [switch]$Optional
        )
        
        $args = @()
        if ($Dev) {
            $args += '--group', 'dev'
        }
        elseif ($Test) {
            $args += '--group', 'test'
        }
        elseif ($Docs) {
            $args += '--group', 'docs'
        }
        if ($Optional) {
            $args += '--optional'
        }
        & poetry add @args @Packages
    }
    Set-Alias -Name poetry-add -Value Add-PoetryDependency -ErrorAction SilentlyContinue

    # Poetry remove
    <#
    .SYNOPSIS
        Removes dependencies from Poetry project.
    .DESCRIPTION
        Removes packages from pyproject.toml. Supports --group flags.
    .PARAMETER Packages
        Package names to remove.
    .PARAMETER Dev
        Remove from dev dependencies (--group dev).
    .PARAMETER Test
        Remove from test dependencies (--group test).
    .PARAMETER Docs
        Remove from docs dependencies (--group docs).
    .EXAMPLE
        Remove-PoetryDependency requests
        Removes requests from production dependencies.
    .EXAMPLE
        Remove-PoetryDependency pytest -Dev
        Removes pytest from dev dependencies.
    #>
    function Remove-PoetryDependency {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Dev,
            [switch]$Test,
            [switch]$Docs
        )
        
        $args = @()
        if ($Dev) {
            $args += '--group', 'dev'
        }
        elseif ($Test) {
            $args += '--group', 'test'
        }
        elseif ($Docs) {
            $args += '--group', 'docs'
        }
        & poetry remove @args @Packages
    }
    Set-Alias -Name poetry-remove -Value Remove-PoetryDependency -ErrorAction SilentlyContinue

    # Poetry update
    <#
    .SYNOPSIS
        Updates Poetry project dependencies.
    .DESCRIPTION
        Updates dependencies to their latest versions within version constraints.
    #>
    function Update-PoetryDependencies {
        [CmdletBinding()]
        param()
        
        & poetry update @args
    }
    Set-Alias -Name poetry-update -Value Update-PoetryDependencies -ErrorAction SilentlyContinue

    # Poetry outdated - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated Poetry dependencies.
    .DESCRIPTION
        Lists all packages that have newer versions available.
        This is equivalent to running 'poetry show --outdated'.
    #>
    function Test-PoetryOutdated {
        [CmdletBinding()]
        param()
        
        & poetry show --outdated
    }
    Set-Alias -Name poetry-outdated -Value Test-PoetryOutdated -ErrorAction SilentlyContinue

    # Poetry self-update - update poetry itself
    <#
    .SYNOPSIS
        Updates Poetry to the latest version.
    .DESCRIPTION
        Updates Poetry itself to the latest version using 'poetry self update'.
    #>
    function Update-PoetrySelf {
        [CmdletBinding()]
        param()
        
        & poetry self update
    }
    Set-Alias -Name poetry-self-update -Value Update-PoetrySelf -ErrorAction SilentlyContinue

    # Poetry export - backup dependencies
    <#
    .SYNOPSIS
        Exports Poetry dependencies to a requirements.txt file.
    .DESCRIPTION
        Creates a requirements.txt file containing all Poetry project dependencies with versions.
        This file can be used to restore packages on another system or after a reinstall.
        Requires poetry-plugin-export to be installed.
    .PARAMETER Path
        Path to save the export file. Defaults to "requirements.txt" in current directory.
    .PARAMETER WithoutHashes
        Exclude hash information from the export.
    .PARAMETER Dev
        Include dev dependencies in the export.
    .EXAMPLE
        Export-PoetryDependencies
        Exports dependencies to requirements.txt in current directory.
    .EXAMPLE
        Export-PoetryDependencies -Path "C:\backup\poetry-requirements.txt"
        Exports dependencies to a specific file.
    .EXAMPLE
        Export-PoetryDependencies -Dev
        Exports dependencies including dev dependencies.
    #>
    function Export-PoetryDependencies {
        [CmdletBinding()]
        param(
            [string]$Path = 'requirements.txt',
            [switch]$WithoutHashes,
            [switch]$Dev
        )
        
        $args = @('export', '-f', 'requirements.txt', '--output', $Path)
        if ($WithoutHashes) {
            $args += '--without-hashes'
        }
        if ($Dev) {
            $args += '--with', 'dev'
        }
        & poetry @args
    }
    Set-Alias -Name poetryexport -Value Export-PoetryDependencies -ErrorAction SilentlyContinue
    Set-Alias -Name poetrybackup -Value Export-PoetryDependencies -ErrorAction SilentlyContinue

    # Poetry install from requirements - restore dependencies
    <#
    .SYNOPSIS
        Restores Poetry dependencies from a requirements.txt file.
    .DESCRIPTION
        Installs all packages listed in a requirements.txt file using pip.
        This is useful for restoring packages after a system reinstall or on a new machine.
        Note: Poetry projects should typically use 'poetry install' instead, but this
        function allows restoring from exported requirements.txt files.
    .PARAMETER Path
        Path to the requirements.txt file to import. Defaults to "requirements.txt" in current directory.
    .PARAMETER NoDeps
        Don't install dependencies (--no-deps flag for pip).
    .EXAMPLE
        Import-PoetryDependencies
        Restores dependencies from requirements.txt in current directory.
    .EXAMPLE
        Import-PoetryDependencies -Path "C:\backup\poetry-requirements.txt"
        Restores dependencies from a specific file.
    #>
    function Import-PoetryDependencies {
        [CmdletBinding()]
        param(
            [string]$Path = 'requirements.txt',
            [switch]$NoDeps
        )
        
        if (-not (Test-Path -LiteralPath $Path)) {
            Write-Error "Requirements file not found: $Path"
            return
        }
        
        if (Test-CachedCommand pip) {
            $args = @('install', '-r', $Path)
            if ($NoDeps) {
                $args += '--no-deps'
            }
            & pip @args
        }
        else {
            Write-MissingToolWarning -Tool 'pip' -InstallHint 'Install with: python -m ensurepip --upgrade'
        }
    }
    Set-Alias -Name poetryimport -Value Import-PoetryDependencies -ErrorAction SilentlyContinue
    Set-Alias -Name poetryrestore -Value Import-PoetryDependencies -ErrorAction SilentlyContinue
}
else {
    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        Get-PreferenceAwareInstallHint -ToolName 'poetry' -ToolType 'python-package' -DefaultInstallCommand 'scoop install poetry (or uv tool install poetry, or pip install poetry, or curl -sSL https://install.python-poetry.org | python -)'
    }
    else {
        'Install with: scoop install poetry (or uv tool install poetry, or pip install poetry, or curl -sSL https://install.python-poetry.org | python -)'
    }
    Write-MissingToolWarning -Tool 'poetry' -InstallHint $installHint
}
