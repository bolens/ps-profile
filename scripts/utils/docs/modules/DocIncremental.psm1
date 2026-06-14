<#
scripts/utils/docs/modules/DocIncremental.psm1

.SYNOPSIS
    Incremental documentation generation cache utilities.

.DESCRIPTION
    Tracks per-file documentation parse results and re-parses only changed
    profile sources when generating API documentation.
#>

$script:DocGenerationCacheVersion = 2

<#
.SYNOPSIS
    Imports the documentation parser module when it is not already loaded.

.DESCRIPTION
    Loads DocParser.psm1 on demand so incremental generation can call
    Get-DocumentedCommands without requiring the module at import time.
#>
function Import-DocParserModule {
    if (Get-Command Get-DocumentedCommands -ErrorAction SilentlyContinue) {
        return
    }

    $docParserPath = Join-Path $PSScriptRoot 'DocParser.psm1'
    if (Test-Path $docParserPath) {
        Import-Module $docParserPath -DisableNameChecking -Force -ErrorAction Stop
    }
}

<#
.SYNOPSIS
    Builds a relative-path to full-path map for profile scripts.

.DESCRIPTION
    Recursively indexes .ps1 files under a profile directory for cache lookups.

.PARAMETER ProfilePath
    Root profile directory to scan.

.OUTPUTS
    System.Collections.Generic.Dictionary[string,string]

.EXAMPLE
    Get-ProfileScriptFileMap -ProfilePath ./profile.d
#>
function Get-ProfileScriptFileMap {
    [OutputType([System.Collections.Generic.Dictionary[string, string]])]
    param(
        [Parameter(Mandatory)]
        [string]$ProfilePath
    )

    $map = [System.Collections.Generic.Dictionary[string, string]]::new([StringComparer]::OrdinalIgnoreCase)
    $resolvedProfile = (Resolve-Path -LiteralPath $ProfilePath).Path

    Get-ChildItem -LiteralPath $resolvedProfile -Filter '*.ps1' -Recurse -File | ForEach-Object {
        $relativePath = Get-RelativeDocPath -BasePath $resolvedProfile -FullPath $_.FullName
        if ($relativePath) {
            $map[$relativePath] = $_.FullName
        }
    }

    return $map
}

<#
.SYNOPSIS
    Converts a full file path to a profile-relative documentation path.

.DESCRIPTION
    Returns a forward-slash relative path suitable for cache keys and docs output.

.PARAMETER BasePath
    Root directory used as the relative base.

.PARAMETER FullPath
    Absolute or resolved file path.

.OUTPUTS
    System.String

.EXAMPLE
    Get-RelativeDocPath -BasePath $profileRoot -FullPath $file.FullName
#>
function Get-RelativeDocPath {
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$BasePath,

        [Parameter(Mandatory)]
        [string]$FullPath
    )

    $baseUri = [Uri]::new(($BasePath.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar))
    $fullUri = [Uri]::new($FullPath)
    $relative = [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($fullUri).ToString())
    return $relative -replace '\\', '/'
}

<#
.SYNOPSIS
    Returns the UTC last-write timestamp for a file.

.DESCRIPTION
    Formats the file last-write time as an ISO 8601 UTC string for cache keys.

.PARAMETER Path
    Path to the file.

.OUTPUTS
    System.String

.EXAMPLE
    Get-FileWriteTimeUtc -Path ./profile.d/git.ps1
#>
function Get-FileWriteTimeUtc {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return (Get-Item -LiteralPath $Path).LastWriteTimeUtc.ToString('o')
}

<#
.SYNOPSIS
    Normalizes cache write-time values to ISO 8601 UTC strings.

.DESCRIPTION
    Converts DateTime values and parseable timestamp strings into UTC ISO text.

.PARAMETER Value
    DateTime value or parseable timestamp string.

.OUTPUTS
    System.String

.EXAMPLE
    ConvertTo-CacheWriteTimeString -Value (Get-Date)
#>
function ConvertTo-CacheWriteTimeString {
    param(
        $Value
    )

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [datetime]) {
        return $Value.ToUniversalTime().ToString('o')
    }

    $parsed = [datetime]::MinValue
    $text = [string]$Value
    if ([datetime]::TryParse($text, [ref]$parsed)) {
        return $parsed.ToUniversalTime().ToString('o')
    }

    return $text
}

<#
.SYNOPSIS
    Loads a documentation generation cache from disk.

.DESCRIPTION
    Validates cache version and profile path before returning cached file entries.

.PARAMETER CachePath
    Path to the JSON cache file.

.PARAMETER ProfilePath
    Profile root path used when the cache was created.

.OUTPUTS
    PSCustomObject

.EXAMPLE
    Import-DocGenerationCache -CachePath ./.doc-cache.json -ProfilePath ./profile.d
#>
function Import-DocGenerationCache {
    param(
        [Parameter(Mandatory)]
        [string]$CachePath,

        [Parameter(Mandatory)]
        [string]$ProfilePath
    )

    if (-not (Test-Path -LiteralPath $CachePath)) {
        return $null
    }

    try {
        $raw = Get-Content -LiteralPath $CachePath -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $null
        }

        $cache = $raw | ConvertFrom-Json
        if (-not $cache -or $cache.version -ne $script:DocGenerationCacheVersion) {
            return $null
        }

        $resolvedProfile = (Resolve-Path -LiteralPath $ProfilePath).Path
        if ($cache.profilePath -ne $resolvedProfile) {
            return $null
        }

        return $cache
    }
    catch {
        return $null
    }
}

<#
.SYNOPSIS
    Persists documentation generation cache data to disk.

.DESCRIPTION
    Serializes per-file documentation parse results to JSON on disk.

.PARAMETER CachePath
    Destination JSON cache file path.

.PARAMETER ProfilePath
    Profile root path associated with the cache.

.PARAMETER FileEntries
    Hashtable of per-file cached command metadata.

.EXAMPLE
    Export-DocGenerationCache -CachePath ./.doc-cache.json -ProfilePath ./profile.d -FileEntries $entries
#>
function Export-DocGenerationCache {
    param(
        [Parameter(Mandatory)]
        [string]$CachePath,

        [Parameter(Mandatory)]
        [string]$ProfilePath,

        [Parameter(Mandatory)]
        [hashtable]$FileEntries
    )

    $resolvedProfile = (Resolve-Path -LiteralPath $ProfilePath).Path
    $payload = [ordered]@{
        version     = $script:DocGenerationCacheVersion
        profilePath = $resolvedProfile
        files       = $FileEntries
    }

    $json = $payload | ConvertTo-Json -Depth 12
    $parent = Split-Path -Parent $CachePath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Set-Content -LiteralPath $CachePath -Value $json -Encoding UTF8 -NoNewline:$false
}

<#
.SYNOPSIS
    Converts parsed command objects into cache-serializable hashtables.

.DESCRIPTION
    Projects function and alias documentation objects into plain hashtables for
    JSON cache export.

.PARAMETER Items
    Function or alias documentation objects to serialize.

.OUTPUTS
    System.Object[]

.EXAMPLE
    ConvertTo-CacheCommandList -Items $functions
#>
function ConvertTo-CacheCommandList {
    param(
        [AllowNull()]
        $Items
    )

    if (-not $Items) {
        return @()
    }

    return @($Items | ForEach-Object {
            @{
                Name        = $_.Name
                Signature   = $_.Signature
                Synopsis    = $_.Synopsis
                Description = $_.Description
                Parameters  = @($_.Parameters)
                Examples    = @($_.Examples)
                Outputs     = $_.Outputs
                Notes       = $_.Notes
                Inputs      = $_.Inputs
                Links       = @($_.Links)
                File        = $_.File
                Target      = $_.Target
            }
        })
}

function Get-DocumentedCommandsIncremental {
    <#
    .SYNOPSIS
        Parses profile sources using a file cache and returns merged command data.

    .DESCRIPTION
        Reuses cached per-file parse results when timestamps match and parses
        only changed or dependent files before exporting an updated cache.

    .PARAMETER ProfilePath
        Root profile directory to scan.

    .PARAMETER CachePath
        JSON cache file path for reading and writing parse results.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        Get-DocumentedCommandsIncremental -ProfilePath ./profile.d -CachePath ./.doc-cache.json
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$ProfilePath,

        [Parameter(Mandatory)]
        [string]$CachePath
    )

    Import-DocParserModule

    $fileMap = Get-ProfileScriptFileMap -ProfilePath $ProfilePath
    $cache = Import-DocGenerationCache -CachePath $CachePath -ProfilePath $ProfilePath
    $cachedFiles = @{}
    if ($cache -and $cache.files) {
        $cache.files.PSObject.Properties | ForEach-Object {
            $cachedFiles[$_.Name] = $_.Value
        }
    }

    $filesToParse = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $removedCommandNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    foreach ($relativePath in ($fileMap.Keys | Sort-Object)) {
        $fullPath = $fileMap[$relativePath]
        $writeTime = Get-FileWriteTimeUtc -Path $fullPath
        $cachedWriteTime = if ($cachedFiles.ContainsKey($relativePath)) {
            ConvertTo-CacheWriteTimeString -Value $cachedFiles[$relativePath].lastWriteTimeUtc
        }
        else {
            $null
        }

        if (-not $cachedWriteTime -or $cachedWriteTime -ne $writeTime) {
            [void]$filesToParse.Add($relativePath)
        }
    }

    foreach ($relativePath in $cachedFiles.Keys) {
        if (-not $fileMap.ContainsKey($relativePath)) {
            foreach ($entry in @($cachedFiles[$relativePath].functions)) {
                if ($entry.Name) { [void]$removedCommandNames.Add($entry.Name) }
            }
            foreach ($entry in @($cachedFiles[$relativePath].aliases)) {
                if ($entry.Name) { [void]$removedCommandNames.Add($entry.Name) }
            }
        }
    }

    $parseFullPaths = foreach ($relativePath in $filesToParse) { $fileMap[$relativePath] }
    $freshByFile = @{}
    if ($parseFullPaths.Count -gt 0) {
        $freshData = Get-DocumentedCommands -ProfilePath $ProfilePath -Files $parseFullPaths
        foreach ($function in $freshData.Functions) {
            $relativePath = Get-RelativeDocPath -BasePath (Resolve-Path -LiteralPath $ProfilePath).Path -FullPath $function.File
            if (-not $freshByFile.ContainsKey($relativePath)) {
                $freshByFile[$relativePath] = @{
                    Functions = [System.Collections.Generic.List[PSCustomObject]]::new()
                    Aliases   = [System.Collections.Generic.List[PSCustomObject]]::new()
                }
            }
            $freshByFile[$relativePath].Functions.Add($function)
        }
        foreach ($alias in $freshData.Aliases) {
            $relativePath = Get-RelativeDocPath -BasePath (Resolve-Path -LiteralPath $ProfilePath).Path -FullPath $alias.File
            if (-not $freshByFile.ContainsKey($relativePath)) {
                $freshByFile[$relativePath] = @{
                    Functions = [System.Collections.Generic.List[PSCustomObject]]::new()
                    Aliases   = [System.Collections.Generic.List[PSCustomObject]]::new()
                }
            }
            $freshByFile[$relativePath].Aliases.Add($alias)
        }

        $changedFunctionNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($function in $freshData.Functions) {
            if ($function.Name) { [void]$changedFunctionNames.Add($function.Name) }
        }

        foreach ($relativePath in $cachedFiles.Keys) {
            if ($filesToParse.Contains($relativePath)) {
                continue
            }

            foreach ($alias in @($cachedFiles[$relativePath].aliases)) {
                if ($alias.Target -and $changedFunctionNames.Contains($alias.Target)) {
                    [void]$filesToParse.Add($relativePath)
                    break
                }
            }
        }

        $additionalPaths = foreach ($relativePath in $filesToParse) {
            if (-not $freshByFile.ContainsKey($relativePath)) { $fileMap[$relativePath] }
        }
        if ($additionalPaths.Count -gt 0) {
            $dependentData = Get-DocumentedCommands -ProfilePath $ProfilePath -Files $additionalPaths
            foreach ($function in $dependentData.Functions) {
                $relativePath = Get-RelativeDocPath -BasePath (Resolve-Path -LiteralPath $ProfilePath).Path -FullPath $function.File
                if (-not $freshByFile.ContainsKey($relativePath)) {
                    $freshByFile[$relativePath] = @{
                        Functions = [System.Collections.Generic.List[PSCustomObject]]::new()
                        Aliases   = [System.Collections.Generic.List[PSCustomObject]]::new()
                    }
                }
                $freshByFile[$relativePath].Functions.Add($function)
            }
            foreach ($alias in $dependentData.Aliases) {
                $relativePath = Get-RelativeDocPath -BasePath (Resolve-Path -LiteralPath $ProfilePath).Path -FullPath $alias.File
                if (-not $freshByFile.ContainsKey($relativePath)) {
                    $freshByFile[$relativePath] = @{
                        Functions = [System.Collections.Generic.List[PSCustomObject]]::new()
                        Aliases   = [System.Collections.Generic.List[PSCustomObject]]::new()
                    }
                }
                $freshByFile[$relativePath].Aliases.Add($alias)
            }
        }
    }

    $functions = [System.Collections.Generic.List[PSCustomObject]]::new()
    $aliases = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seenAliasNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $newCacheEntries = @{}
    $changedCommandNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    foreach ($relativePath in ($fileMap.Keys | Sort-Object)) {
        $fullPath = $fileMap[$relativePath]
        $writeTime = Get-FileWriteTimeUtc -Path $fullPath
        $fileFunctions = [System.Collections.Generic.List[PSCustomObject]]::new()
        $fileAliases = [System.Collections.Generic.List[PSCustomObject]]::new()

        if ($freshByFile.ContainsKey($relativePath)) {
            $fileFunctions = $freshByFile[$relativePath].Functions
            $fileAliases = $freshByFile[$relativePath].Aliases
            foreach ($entry in $fileFunctions) {
                if ($entry.Name) { [void]$changedCommandNames.Add($entry.Name) }
            }
            foreach ($entry in $fileAliases) {
                if ($entry.Name) { [void]$changedCommandNames.Add($entry.Name) }
            }
        }
        elseif ($cachedFiles.ContainsKey($relativePath)) {
            foreach ($entry in @($cachedFiles[$relativePath].functions)) {
                $fileFunctions.Add([PSCustomObject]$entry)
            }
            foreach ($entry in @($cachedFiles[$relativePath].aliases)) {
                $fileAliases.Add([PSCustomObject]$entry)
            }
        }
        else {
            $parsed = Get-DocumentedCommands -ProfilePath $ProfilePath -Files @($fullPath)
            foreach ($entry in $parsed.Functions) {
                $fileFunctions.Add($entry)
                if ($entry.Name) { [void]$changedCommandNames.Add($entry.Name) }
            }
            foreach ($entry in $parsed.Aliases) {
                $fileAliases.Add($entry)
                if ($entry.Name) { [void]$changedCommandNames.Add($entry.Name) }
            }
        }

        foreach ($entry in $fileFunctions) { $functions.Add($entry) }
        foreach ($entry in $fileAliases) {
            if ($entry.Name -and $seenAliasNames.Add($entry.Name)) {
                $aliases.Add($entry)
            }
        }

        $newCacheEntries[$relativePath] = @{
            lastWriteTimeUtc = $writeTime
            functions        = ConvertTo-CacheCommandList -Items $fileFunctions
            aliases          = ConvertTo-CacheCommandList -Items $fileAliases
        }
    }

    foreach ($name in $removedCommandNames) {
        [void]$changedCommandNames.Add($name)
    }

    Export-DocGenerationCache -CachePath $CachePath -ProfilePath $ProfilePath -FileEntries $newCacheEntries

    Import-DocParserModule
    $functions = Get-DeduplicatedDocumentedCommands -Commands $functions -PropertyName 'Name'
    $aliases = Get-DeduplicatedDocumentedCommands -Commands $aliases -PropertyName 'Name'

    $parseMode = if ($cache) { 'Incremental' } else { 'Full' }

    return [PSCustomObject]@{
        Functions           = $functions
        Aliases             = $aliases
        ChangedCommandNames = $changedCommandNames
        RemovedCommandNames = $removedCommandNames
        ParseMode           = $parseMode
        ParsedFileCount     = $filesToParse.Count
    }
}

Export-ModuleMember -Function @(
    'Get-DocumentedCommandsIncremental'
    'Import-DocGenerationCache'
    'Get-ProfileScriptFileMap'
)
