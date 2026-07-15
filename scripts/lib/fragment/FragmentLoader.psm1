<#
scripts/lib/fragment/FragmentLoader.psm1

.SYNOPSIS
    On-demand profile fragment loading helpers.

.DESCRIPTION
    Loads profile.d fragments by name or by registered command, resolving
    dependencies through the fragment loading modules when available.
#>

$script:FragmentLoaderLibDir = $PSScriptRoot

foreach ($dependencyModule in @('FragmentIdempotency.psm1', 'FragmentLoading.psm1', 'FragmentErrorHandling.psm1')) {
    $dependencyPath = Join-Path $script:FragmentLoaderLibDir $dependencyModule
    if (Test-Path -LiteralPath $dependencyPath) {
        Import-Module $dependencyPath -DisableNameChecking -ErrorAction SilentlyContinue
    }
}

function Get-ProfileDirectory {
    <#
.SYNOPSIS
        Returns the profile.d directory path.

    .DESCRIPTION
        Uses ProfileFragmentRoot or ProfileDir when set, otherwise derives the
        profile.d path from the repository layout.

    .OUTPUTS
        System.String. Absolute or relative path to profile.d.

    .EXAMPLE
    Get-ProfileDirectory
#>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($global:ProfileFragmentRoot -and -not [string]::IsNullOrWhiteSpace($global:ProfileFragmentRoot) -and
        (Test-Path -LiteralPath $global:ProfileFragmentRoot)) {
        return $global:ProfileFragmentRoot
    }

    if ($global:ProfileDir -and -not [string]::IsNullOrWhiteSpace($global:ProfileDir) -and
        (Test-Path -LiteralPath $global:ProfileDir)) {
        return $global:ProfileDir
    }

    $repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $script:FragmentLoaderLibDir))
    return Join-Path $repoRoot 'profile.d'
}

function Get-FragmentPath {
    <#
    .SYNOPSIS
        Resolves the expected path for a fragment file under profile.d.

    .DESCRIPTION
        Checks the profile root directly, then searches recursively for
        <FragmentName>.ps1 when the direct path is missing.

    .PARAMETER FragmentName
        Fragment base name without the .ps1 extension.

    .OUTPUTS
        System.String. Resolved fragment path, or the expected direct path when not found.

    .EXAMPLE
        Get-FragmentPath -FragmentName 'git'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$FragmentName
    )

    if ([string]::IsNullOrWhiteSpace($FragmentName)) {
        return $null
    }

    $profileDir = Get-ProfileDirectory
    $candidate = Join-Path $profileDir "$FragmentName.ps1"
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }

    $matches = Get-ChildItem -LiteralPath $profileDir -Filter "$FragmentName.ps1" -Recurse -File -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($matches) {
        return $matches.FullName
    }

    return $candidate
}

function Test-FragmentLoaded {
    <#
    .SYNOPSIS
        Tests whether a fragment has already been loaded.

    .DESCRIPTION
        Delegates to FragmentIdempotency when available, otherwise checks global
        load markers such as <FragmentName>Loaded and __psprofile_fragment_loaded.

    .PARAMETER FragmentName
        Fragment base name to test.

    .OUTPUTS
        System.Boolean. True when the fragment is already loaded.

    .EXAMPLE
        Test-FragmentLoaded -FragmentName 'git'
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$FragmentName
    )

    if ([string]::IsNullOrWhiteSpace($FragmentName)) {
        return $false
    }

    try {
        $idempotencyCmd = Get-Command -Module FragmentIdempotency -Name 'Test-FragmentLoaded' -ErrorAction SilentlyContinue
        if ($idempotencyCmd) {
            return [bool](& $idempotencyCmd -FragmentName $FragmentName)
        }
    }
    catch {
        # Fall through to global-state checks
    }

    $variableName = "${FragmentName}Loaded"
    if (Get-Variable -Name $variableName -Scope Global -ErrorAction SilentlyContinue) {
        return $true
    }

    if ($global:__psprofile_fragment_loaded -and $global:__psprofile_fragment_loaded.ContainsKey($FragmentName)) {
        return [bool]$global:__psprofile_fragment_loaded[$FragmentName]
    }

    return $false
}

function Get-FragmentDependencies {
    <#
    .SYNOPSIS
        Returns dependency fragment names for a fragment file.

    .DESCRIPTION
        Uses FragmentLoading helpers when available, otherwise parses # Requires
        and #Requires -Fragment directives from the fragment source.

    .PARAMETER FragmentName
        Fragment base name associated with the file.

    .PARAMETER FragmentPath
        Path to the fragment .ps1 file.

    .OUTPUTS
        System.String[]. Dependency fragment names in load order.

    .EXAMPLE
        Get-FragmentDependencies -FragmentName 'git' -FragmentPath $path
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$FragmentName,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$FragmentPath
    )

    $dependencies = [System.Collections.Generic.List[string]]::new()

    if ([string]::IsNullOrWhiteSpace($FragmentPath)) {
        return ,@()
    }

    if (-not (Test-Path -LiteralPath $FragmentPath)) {
        return ,@()
    }

    try {
        $loadingCmd = Get-Command -Module FragmentLoading -Name 'Get-FragmentDependencies' -ErrorAction SilentlyContinue
        if ($loadingCmd) {
            $moduleDeps = & $loadingCmd -FragmentFile $FragmentPath
            if ($moduleDeps -and $moduleDeps.Count -gt 0) {
                return @([string[]]$moduleDeps)
            }
        }
    }
    catch {
        # Fall through to manual parsing
    }

    try {
        $content = Get-Content -LiteralPath $FragmentPath -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($content)) {
            return ,@()
        }

        $requiresLine = [regex]::Match($content, '(?m)^#\s*Requires:\s*(.+?)\s*$')
        if ($requiresLine.Success) {
            foreach ($dep in ($requiresLine.Groups[1].Value -split ',')) {
                $trimmed = $dep.Trim()
                if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
                    $dependencies.Add($trimmed)
                }
            }
        }

        $requiresFragment = [regex]::Matches($content, "#Requires\s+-Fragment\s+['""]([^'""]+)['""]", 'IgnoreCase')
        foreach ($match in $requiresFragment) {
            $trimmed = $match.Groups[1].Value.Trim()
            if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
                $dependencies.Add($trimmed)
            }
        }
    }
    catch {
        return ,@()
    }

    if ($dependencies.Count -eq 0) {
        return ,@()
    }

    return $dependencies.ToArray()
}

function Invoke-FragmentLoaderOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OperationName,

        [Parameter(Mandatory)]
        [hashtable]$Context,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )

    if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
        return Invoke-WithWideEvent -OperationName $OperationName -Context $Context -ScriptBlock $ScriptBlock
    }

    return & $ScriptBlock
}

function Resolve-FragmentsToLoad {
    <#
    .SYNOPSIS
        Builds the ordered fragment load list for a fragment name.

    .DESCRIPTION
        Walks dependency relationships depth-first and returns fragment names in
        the order they should be loaded.

    .PARAMETER FragmentName
        Root fragment to resolve.

    .PARAMETER LoadDependencies
        When false, returns only the requested fragment name.

    .OUTPUTS
        System.String[]. Fragment names in load order.

    .EXAMPLE
        Resolve-FragmentsToLoad -FragmentName 'git'
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$FragmentName,

        [bool]$LoadDependencies = $true
    )

    $toLoad = [System.Collections.Generic.List[string]]::new()
    $visited = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    function Add-FragmentWithDependencies {
        param([string]$Name)

        if ([string]::IsNullOrWhiteSpace($Name) -or $visited.Contains($Name)) {
            return
        }

        [void]$visited.Add($Name)
        $fragmentPath = Get-FragmentPath -FragmentName $Name

        if ($LoadDependencies -and $fragmentPath) {
            foreach ($dep in (Get-FragmentDependencies -FragmentName $Name -FragmentPath $fragmentPath)) {
                Add-FragmentWithDependencies -Name $dep
            }
        }

        if (-not $toLoad.Contains($Name)) {
            $toLoad.Add($Name)
        }
    }

    Add-FragmentWithDependencies -Name $FragmentName
    return @($toLoad)
}

function Load-Fragment {
    <#
    .SYNOPSIS
        Loads a profile fragment and optional dependencies from profile.d.

    .DESCRIPTION
        Resolves dependencies, dot-sources each fragment safely when possible,
        and records load state in global idempotency markers.

    .PARAMETER FragmentName
        Fragment base name to load.

    .PARAMETER LoadDependencies
        When true, loads declared dependencies before the requested fragment.

    .OUTPUTS
        System.Boolean. True when at least one required fragment was loaded.

    .EXAMPLE
        Load-Fragment -FragmentName 'git'
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$FragmentName,

        [bool]$LoadDependencies = $true
    )

    if ([string]::IsNullOrWhiteSpace($FragmentName)) {
        return $false
    }

    $operation = {
        $fragmentsToLoad = Resolve-FragmentsToLoad -FragmentName $FragmentName -LoadDependencies:$LoadDependencies
        $loadedAny = $false

        foreach ($name in $fragmentsToLoad) {
            if (Test-FragmentLoaded -FragmentName $name) {
                $loadedAny = $true
                continue
            }

            $fragmentPath = Get-FragmentPath -FragmentName $name
            if (-not $fragmentPath -or -not (Test-Path -LiteralPath $fragmentPath)) {
                continue
            }

            $originalProfileFragmentRoot = $global:ProfileFragmentRoot
            $originalFragmentContext = $null
            if (Get-Variable -Name 'CurrentFragmentContext' -Scope Global -ErrorAction SilentlyContinue) {
                $originalFragmentContext = $global:CurrentFragmentContext
            }

            try {
                $global:ProfileFragmentRoot = Split-Path -Parent $fragmentPath
                $global:CurrentFragmentContext = [System.IO.Path]::GetFileNameWithoutExtension($fragmentPath)

                $loaded = $false
                if (Get-Command Invoke-FragmentSafely -ErrorAction SilentlyContinue) {
                    $loaded = Invoke-FragmentSafely -FragmentName $name -FragmentPath $fragmentPath
                }
                else {
                    . $fragmentPath
                    $loaded = $true
                }

                if ($loaded) {
                    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
                        $null = Set-FragmentLoaded -FragmentName $name
                    }
                    elseif (-not $global:__psprofile_fragment_loaded) {
                        $global:__psprofile_fragment_loaded = @{}
                    }

                    $global:__psprofile_fragment_loaded[$name] = $true
                    $loadedAny = $true
                }
            }
            catch {
                continue
            }
            finally {
                $global:ProfileFragmentRoot = $originalProfileFragmentRoot
                if ($null -ne $originalFragmentContext) {
                    $global:CurrentFragmentContext = $originalFragmentContext
                }
                else {
                    Remove-Variable -Name 'CurrentFragmentContext' -Scope Global -ErrorAction SilentlyContinue
                }
            }
        }

        return $loadedAny
    }

    try {
        return [bool](Invoke-FragmentLoaderOperation -OperationName 'fragment-loader.load' -Context @{
            fragment_name = $FragmentName
        } -ScriptBlock $operation)
    }
    catch {
        return $false
    }
}

function Load-FragmentForCommand {
    <#
    .SYNOPSIS
        Loads the fragment that owns a registered command.

    .DESCRIPTION
        Looks up the command in the fragment registry and loads the owning
        fragment plus its dependencies.

    .PARAMETER CommandName
        Registered command name that triggered on-demand loading.

    .OUTPUTS
        System.Boolean. True when the owning fragment was loaded successfully.

    .EXAMPLE
        Load-FragmentForCommand -CommandName 'gs'
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$CommandName
    )

    if ([string]::IsNullOrWhiteSpace($CommandName)) {
        return $false
    }

    $operation = {
        if (-not (Get-Command Get-FragmentForCommand -ErrorAction SilentlyContinue)) {
            return $false
        }

        $fragmentName = Get-FragmentForCommand -CommandName $CommandName
        if ([string]::IsNullOrWhiteSpace($fragmentName)) {
            return $false
        }

        return Load-Fragment -FragmentName $fragmentName -LoadDependencies:$true
    }

    try {
        return [bool](Invoke-FragmentLoaderOperation -OperationName 'fragment-loader.load-for-command' -Context @{
            command_name = $CommandName
        } -ScriptBlock $operation)
    }
    catch {
        return $false
    }
}

Export-ModuleMember -Function @(
    'Get-ProfileDirectory'
    'Get-FragmentPath'
    'Test-FragmentLoaded'
    'Get-FragmentDependencies'
    'Load-Fragment'
    'Load-FragmentForCommand'
)
