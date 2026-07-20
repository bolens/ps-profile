<#
scripts/lib/fragment/FragmentCommandRegistry.psm1

.SYNOPSIS
    Fragment command registry for on-demand fragment command access.

.DESCRIPTION
    Registers fragment commands (functions and aliases), provides lookup/query
    helpers, and supports export/import for caching.
#>

enum FragmentCommandType {
    Function
    Alias
    Cmdlet
    Application
}

function Initialize-FragmentCommandRegistry {
    <#
    .SYNOPSIS
        Ensures the global fragment command registry exists.

    .DESCRIPTION
        Creates an empty hashtable at $global:FragmentCommandRegistry when the
        registry has not been initialized in the current session.
    #>
    if (-not (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) -or
        $null -eq $global:FragmentCommandRegistry) {
        $global:FragmentCommandRegistry = @{}
    }
}

function ConvertTo-FragmentCommandTypeString {
    <#
.SYNOPSIS
        Normalizes a FragmentCommandType value to its string name.


.DESCRIPTION
    Normalizes a FragmentCommandType value to its string name.

    .PARAMETER CommandType
        FragmentCommandType enum value or string representation.


    .PARAMETER CommandType
    FragmentCommandType enum value or string representation.

    .OUTPUTS
        System.String. Enum name, or an empty string when the input is null.


    .OUTPUTS
    System.String. Enum name, or an empty string when the input is null.

    .EXAMPLE

    .EXAMPLE
        ConvertTo-FragmentCommandTypeString -CommandType ([FragmentCommandType]::Alias)
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        $CommandType
    )

    if ($CommandType -is [FragmentCommandType]) {
        return $CommandType.ToString()
    }

    if ($null -eq $CommandType) {
        return ''
    }

    return [string]$CommandType
}

function Register-FragmentCommand {
    <#
    .SYNOPSIS
        Registers a command in the global fragment command registry.

    .DESCRIPTION
        Stores command metadata keyed by command name so on-demand loading can
        resolve the owning fragment and command type.

    .PARAMETER CommandName
        Function, alias, or command name to register.

    .PARAMETER FragmentName
        Fragment that owns the command.

    .PARAMETER CommandType
        FragmentCommandType value or equivalent string.

    .PARAMETER Target
        Optional alias target or related command name.

    .PARAMETER Dependencies
        Optional fragment dependency names associated with the command.

    .OUTPUTS
        System.Boolean. True when the command was registered.

    .EXAMPLE
        Register-FragmentCommand -CommandName 'gs' -FragmentName 'git' -CommandType 'Alias' -Target 'git status'
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$CommandName,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$FragmentName,

        [Parameter(Mandatory)]
        $CommandType,

        [string]$Target,

        [string[]]$Dependencies
    )

    if ([string]::IsNullOrWhiteSpace($CommandName) -or [string]::IsNullOrWhiteSpace($FragmentName)) {
        return $false
    }

    Initialize-FragmentCommandRegistry

    $typeString = ConvertTo-FragmentCommandTypeString -CommandType $CommandType
    if ([string]::IsNullOrWhiteSpace($typeString)) {
        return $false
    }

    $entry = [ordered]@{
        Fragment     = $FragmentName
        Type         = $typeString
        RegisteredAt = (Get-Date).ToString('o')
    }

    if (-not [string]::IsNullOrWhiteSpace($Target)) {
        $entry.Target = $Target
    }

    if ($Dependencies) {
        $entry.Dependencies = @($Dependencies)
    }

    $global:FragmentCommandRegistry[$CommandName] = $entry
    return $true
}

function Get-FragmentForCommand {
    <#
    .SYNOPSIS
        Returns the fragment name that owns a registered command.

    .DESCRIPTION
        Looks up a command name in the global fragment registry.

    .PARAMETER CommandName
        Registered command name to look up.

    .OUTPUTS
        System.String. Owning fragment name, or null when not registered.

    .EXAMPLE
        Get-FragmentForCommand -CommandName 'gs'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$CommandName
    )

    if ([string]::IsNullOrWhiteSpace($CommandName)) {
        return $null
    }

    if (-not (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) -or
        $null -eq $global:FragmentCommandRegistry) {
        return $null
    }

    if (-not $global:FragmentCommandRegistry.ContainsKey($CommandName)) {
        return $null
    }

    $entry = $global:FragmentCommandRegistry[$CommandName]
    if ($null -eq $entry) {
        return $null
    }

    return $entry.Fragment
}

function Get-CommandRegistryInfo {
    <#
    .SYNOPSIS
        Returns registry metadata for a command.

    .DESCRIPTION
        Copies the registry entry hashtable for inspection or debugging.

    .PARAMETER CommandName
        Registered command name to inspect.

    .OUTPUTS
        System.Collections.Hashtable. Registry entry fields, or null when missing.

    .EXAMPLE
        Get-CommandRegistryInfo -CommandName 'gs'
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$CommandName
    )

    if ([string]::IsNullOrWhiteSpace($CommandName)) {
        return $null
    }

    if (-not (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) -or
        $null -eq $global:FragmentCommandRegistry -or
        -not $global:FragmentCommandRegistry.ContainsKey($CommandName)) {
        return $null
    }

    $entry = $global:FragmentCommandRegistry[$CommandName]
    if ($null -eq $entry) {
        return $null
    }

    $info = @{}
    foreach ($key in $entry.Keys) {
        $info[$key] = $entry[$key]
    }

    return $info
}

function Test-CommandInRegistry {
    <#
    .SYNOPSIS
        Tests whether a command is registered for on-demand loading.

    .DESCRIPTION
        Returns whether the global registry contains the command name.

    .PARAMETER CommandName
        Command name to test.

    .OUTPUTS
        System.Boolean. True when the command exists in the registry.

    .EXAMPLE
        Test-CommandInRegistry -CommandName 'gs'
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

    try {
        if (-not (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) -or
            $null -eq $global:FragmentCommandRegistry) {
            return $false
        }

        return $global:FragmentCommandRegistry.ContainsKey($CommandName)
    }
    catch {
        return $false
    }
}

function Get-CommandsForFragment {
    <#
    .SYNOPSIS
        Lists commands registered for a fragment.

    .DESCRIPTION
        Scans registry entries and returns command names owned by the fragment.

    .PARAMETER FragmentName
        Fragment base name to query.

    .OUTPUTS
        System.String[]. Registered command names for the fragment.

    .EXAMPLE
        Get-CommandsForFragment -FragmentName 'git'
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$FragmentName
    )

    $results = [System.Collections.Generic.List[string]]::new()

    if ([string]::IsNullOrWhiteSpace($FragmentName)) {
        return ,@()
    }

    if (-not (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) -or
        $null -eq $global:FragmentCommandRegistry) {
        return ,@()
    }

    foreach ($commandName in $global:FragmentCommandRegistry.Keys) {
        try {
            $entry = $global:FragmentCommandRegistry[$commandName]
            if ($null -eq $entry) {
                continue
            }

            $entryFragment = $entry.Fragment
            if ($entryFragment -and ($entryFragment -eq $FragmentName)) {
                $results.Add([string]$commandName)
            }
        }
        catch {
            continue
        }
    }

    if ($results.Count -eq 0) {
        return ,@()
    }

    return $results.ToArray()
}

function Export-CommandRegistry {
    <#
    .SYNOPSIS
        Serializes the command registry to JSON.

    .DESCRIPTION
        Exports the in-memory registry to JSON and optionally writes it to disk.

    .PARAMETER Path
        Optional file path to write the JSON export.

    .OUTPUTS
        System.String. JSON representation of the registry.

    .EXAMPLE
        Export-CommandRegistry -Path $cachePath
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$Path
    )

    Initialize-FragmentCommandRegistry

    $exportData = @{}
    foreach ($commandName in $global:FragmentCommandRegistry.Keys) {
        $entry = $global:FragmentCommandRegistry[$commandName]
        if ($null -ne $entry) {
            $exportData[$commandName] = $entry
        }
    }

    $json = $exportData | ConvertTo-Json -Depth 10

    if ($Path) {
        $parent = Split-Path -Parent $Path
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            throw "Parent directory does not exist: $parent"
        }

        Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
    }

    return $json
}

function Import-CommandRegistry {
    <#
    .SYNOPSIS
        Loads a command registry from JSON.

    .DESCRIPTION
        Hydrates the global registry from JSON text or a file.

    .PARAMETER Json
        Registry JSON string to import.

    .PARAMETER Path
        Optional file path to read JSON from when -Json is not provided.

    .PARAMETER Merge
        Merges into the existing registry instead of replacing it.

    .OUTPUTS
        System.Boolean. True when import succeeded.

    .EXAMPLE
        Import-CommandRegistry -Path $cachePath
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string]$Json,

        [string]$Path,

        [switch]$Merge
    )

    try {
        if ($Path) {
            if (-not (Test-Path -LiteralPath $Path)) {
                return $false
            }

            $Json = Get-Content -LiteralPath $Path -Raw
        }

        if ([string]::IsNullOrWhiteSpace($Json)) {
            return $false
        }

        $imported = $Json | ConvertFrom-Json
        if ($null -eq $imported) {
            return $false
        }

        Initialize-FragmentCommandRegistry

        if (-not $Merge) {
            $global:FragmentCommandRegistry.Clear()
        }

        foreach ($property in $imported.PSObject.Properties) {
            $entry = @{}
            foreach ($field in $property.Value.PSObject.Properties) {
                $entry[$field.Name] = $field.Value
            }

            $global:FragmentCommandRegistry[$property.Name] = $entry
        }

        return $true
    }
    catch {
        return $false
    }
}

function Get-CommandRegistryStats {
    <#
.SYNOPSIS
        Summarizes registry counts by type and fragment.

    .DESCRIPTION
        Aggregates registry entries into totals and per-type/per-fragment counts.

    .OUTPUTS
        System.Collections.Hashtable. Totals and per-type/per-fragment counts.

    .EXAMPLE
    Get-CommandRegistryStats
#>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $commandsByType = @{}
    $commandsByFragment = @{}
    $fragmentNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $totalCommands = 0

    if (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) {
        foreach ($commandName in $global:FragmentCommandRegistry.Keys) {
            try {
                $entry = $global:FragmentCommandRegistry[$commandName]
                if ($null -eq $entry) {
                    continue
                }

                $fragment = $entry.Fragment
                $type = $entry.Type
                if ([string]::IsNullOrWhiteSpace($fragment) -or [string]::IsNullOrWhiteSpace($type)) {
                    continue
                }

                $totalCommands++
                [void]$fragmentNames.Add($fragment)

                if (-not $commandsByType.ContainsKey($type)) {
                    $commandsByType[$type] = 0
                }
                $commandsByType[$type] = $commandsByType[$type] + 1

                if (-not $commandsByFragment.ContainsKey($fragment)) {
                    $commandsByFragment[$fragment] = 0
                }
                $commandsByFragment[$fragment] = $commandsByFragment[$fragment] + 1
            }
            catch {
                continue
            }
        }
    }

    return @{
        TotalCommands      = $totalCommands
        Fragments          = $fragmentNames.Count
        CommandsByType     = $commandsByType
        CommandsByFragment = $commandsByFragment
    }
}

function Register-CommandsFromFragment {
    <#
    .SYNOPSIS
        Registers functions and aliases declared in a fragment file.

    .DESCRIPTION
        Parses AST functions plus Set-AgentModeFunction and Set-AgentModeAlias calls.

    .PARAMETER FragmentPath
        Path to the fragment .ps1 file.

    .PARAMETER FragmentName
        Fragment name stored in registry entries.

    .OUTPUTS
        System.Int32. Number of commands registered from the fragment.

    .EXAMPLE
        Register-CommandsFromFragment -FragmentPath $path -FragmentName 'git'
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FragmentPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FragmentName
    )

    $registeredCount = 0

    try {
        if (Get-Command Get-PowerShellAst -ErrorAction SilentlyContinue) {
            $ast = Get-PowerShellAst -Path $FragmentPath
            if ($ast -and (Get-Command Get-FunctionsFromAst -ErrorAction SilentlyContinue)) {
                $functions = Get-FunctionsFromAst -Ast $ast
                foreach ($func in $functions) {
                    if ($func.Name -and $func.Name -notmatch '^global:') {
                        if (Register-FragmentCommand -CommandName $func.Name -FragmentName $FragmentName -CommandType 'Function') {
                            $registeredCount++
                        }
                    }
                }
            }
        }

        $content = Get-Content -LiteralPath $FragmentPath -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $functionMatches = [regex]::Matches($content, "Set-AgentModeFunction\s+-Name\s+['""]([A-Za-z0-9_\-]+)['""]")
            foreach ($match in $functionMatches) {
                $cmdName = $match.Groups[1].Value
                if (-not (Test-CommandInRegistry -CommandName $cmdName)) {
                    if (Register-FragmentCommand -CommandName $cmdName -FragmentName $FragmentName -CommandType 'Function') {
                        $registeredCount++
                    }
                }
            }

            $aliasMatches = [regex]::Matches($content, "Set-AgentModeAlias\s+-Name\s+['""]([A-Za-z0-9_\-]+)['""]")
            foreach ($match in $aliasMatches) {
                $aliasName = $match.Groups[1].Value
                if (-not (Test-CommandInRegistry -CommandName $aliasName)) {
                    if (Register-FragmentCommand -CommandName $aliasName -FragmentName $FragmentName -CommandType 'Alias') {
                        $registeredCount++
                    }
                }
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to parse fragment for commands: $FragmentPath" `
                -OperationName 'fragment-registry.pre-register' -Context @{
                fragment_path = $FragmentPath
                fragment_name = $FragmentName
            } -Code 'AstParseFailed'
        }
    }

    return $registeredCount
}

function Register-AllFragmentCommands {
    <#
    .SYNOPSIS
        Registers commands from a set of fragment files.

    .DESCRIPTION
        Iterates fragment files and aggregates registration statistics.

    .PARAMETER FragmentFiles
        Fragment files to scan for commands.

    .PARAMETER ForceBothParsingModes
        Reserved for compatibility with dual parsing workflows.

    .OUTPUTS
        PSCustomObject. Registration totals and failure counts.

    .EXAMPLE
        Register-AllFragmentCommands -FragmentFiles $files
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo[]]$FragmentFiles,

        [switch]$ForceBothParsingModes
    )

    $registeredCommands = 0
    $failedFragments = 0
    $parsedFragments = 0

    foreach ($fragmentFile in $FragmentFiles) {
        if (-not $fragmentFile -or -not $fragmentFile.FullName) {
            $failedFragments++
            continue
        }

        try {
            $count = Register-CommandsFromFragment -FragmentPath $fragmentFile.FullName -FragmentName $fragmentFile.BaseName
            $registeredCommands += $count
            $parsedFragments++
        }
        catch {
            $failedFragments++
        }
    }

    return [pscustomobject]@{
        TotalFragments     = $FragmentFiles.Count
        RegisteredCommands = $registeredCommands
        FailedFragments    = $failedFragments
        ParsedFragments    = $parsedFragments
        CachedFragments    = 0
    }
}

function Create-CommandProxiesForAutocomplete {
    <#
    .SYNOPSIS
        Creates lightweight command proxies for tab completion.

    .DESCRIPTION
        Registers proxy commands for each command owned by the supplied fragments.

    .PARAMETER FragmentFiles
        Fragment files whose registered commands receive proxies.

    .OUTPUTS
        PSCustomObject. Proxy creation totals and failure counts.

    .EXAMPLE
        Create-CommandProxiesForAutocomplete -FragmentFiles $files
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo[]]$FragmentFiles
    )

    $totalCommands = 0
    $createdProxies = 0
    $failedProxies = 0

    if (-not (Get-Command New-FragmentCommandProxy -ErrorAction SilentlyContinue)) {
        return [pscustomobject]@{
            TotalCommands  = 0
            CreatedProxies = 0
            FailedProxies  = 0
        }
    }

    foreach ($fragmentFile in $FragmentFiles) {
        if (-not $fragmentFile) {
            continue
        }

        $commands = Get-CommandsForFragment -FragmentName $fragmentFile.BaseName
        foreach ($commandName in $commands) {
            $totalCommands++
            if (New-FragmentCommandProxy -CommandName $commandName -FragmentName $fragmentFile.BaseName) {
                $createdProxies++
            }
            else {
                $failedProxies++
            }
        }
    }

    return [pscustomobject]@{
        TotalCommands  = $totalCommands
        CreatedProxies = $createdProxies
        FailedProxies  = $failedProxies
    }
}

Initialize-FragmentCommandRegistry

Export-ModuleMember -Function @(
    'Register-FragmentCommand'
    'Get-FragmentForCommand'
    'Get-CommandRegistryInfo'
    'Test-CommandInRegistry'
    'Get-CommandsForFragment'
    'Export-CommandRegistry'
    'Import-CommandRegistry'
    'Get-CommandRegistryStats'
    'Register-CommandsFromFragment'
    'Register-AllFragmentCommands'
    'Create-CommandProxiesForAutocomplete'
    'Initialize-FragmentCommandRegistry'
)
