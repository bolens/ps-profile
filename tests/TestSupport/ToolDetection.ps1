<#
.SYNOPSIS
    Tool detection and recommendation utilities for tests.

.DESCRIPTION
    Provides functions to detect tool availability, recommend installation commands,
    and gracefully skip tests when optional tools are missing.

.NOTES
    This module is part of the TestSupport utilities and should be imported via TestSupport.ps1
#>

function Resolve-TestToolInstallCommand {
    <#
    .SYNOPSIS
        Resolves a platform-aware install command for a tool in tests.
    .PARAMETER ToolName
        Tool or command name to resolve.
    .PARAMETER ToolType
        Optional tool category forwarded to preference-aware hint resolution.
    .PARAMETER DefaultInstallCommand
        Fallback command when platform helpers are unavailable.
    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,

        [ValidateSet('python-package', 'node-package', 'python-runtime', 'rust-package', 'go-package', 'java-build-tool', 'ruby-package', 'php-package', 'dotnet-package', 'dart-package', 'elixir-package', 'generic')]
        [string]$ToolType = 'generic',

        [string]$DefaultInstallCommand
    )

    $packageName = if (Get-Command Resolve-InstallPackageName -ErrorAction SilentlyContinue) {
        Resolve-InstallPackageName -ToolName $ToolName
    }
    else {
        $ToolName
    }

    if (Get-Command Get-ToolInstallationCommand -ErrorAction SilentlyContinue) {
        return Get-ToolInstallationCommand -ToolName $packageName
    }

    if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        try {
            $hint = Get-PreferenceAwareInstallHint -ToolName $packageName -ToolType $ToolType -DefaultInstallCommand $DefaultInstallCommand
            if ($hint -match '^Install with:\s*(.+)$') {
                return $matches[1]
            }
            if ($hint) {
                return $hint
            }
        }
        catch {
            if ($DefaultInstallCommand) {
                return $DefaultInstallCommand
            }
        }
    }

    if ($DefaultInstallCommand) {
        return $DefaultInstallCommand
    }

    return "scoop install $packageName"
}

function Get-TestToolSkipMessage {
    <#
    .SYNOPSIS
        Builds a Pester skip message with a platform-aware install command.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,

        [string]$Context,

        [ValidateSet('python-package', 'node-package', 'python-runtime', 'rust-package', 'go-package', 'java-build-tool', 'ruby-package', 'php-package', 'dotnet-package', 'dart-package', 'elixir-package', 'generic')]
        [string]$ToolType = 'generic'
    )

    $message = if ($Context) { $Context } else { "$ToolName is not available" }
    $installCommand = Resolve-TestToolInstallCommand -ToolName $ToolName -ToolType $ToolType
    if ($installCommand) {
        $message += ". Install with: $installCommand"
    }

    return $message
}

function Get-TestNodePackageSkipMessage {
    <#
    .SYNOPSIS
        Builds a skip message for one or more Node.js packages.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string[]]$PackageNames,

        [Parameter(Mandatory)]
        [string]$Context
    )

    $commands = foreach ($packageName in $PackageNames) {
        Resolve-TestToolInstallCommand -ToolName $packageName -ToolType 'node-package'
    }
    $uniqueCommands = @($commands | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    if ($uniqueCommands.Count -gt 0) {
        return "$Context. Install with: $($uniqueCommands -join ' and ')"
    }

    return $Context
}

function Get-TestToolsSkipMessage {
    <#
    .SYNOPSIS
        Builds a skip message when any of several tools may satisfy a requirement.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Context,

        [Parameter(Mandatory)]
        [hashtable[]]$Tools
    )

    $commands = foreach ($tool in $Tools) {
        $toolType = if ($tool['ToolType']) { $tool['ToolType'] } else { 'generic' }
        Resolve-TestToolInstallCommand -ToolName $tool['Name'] -ToolType $toolType
    }
    $uniqueCommands = @($commands | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    if ($uniqueCommands.Count -gt 0) {
        return "$Context. Install with: $($uniqueCommands -join ' or ')"
    }

    return $Context
}

function Get-TestInstallCommandCandidates {
    <#
    .SYNOPSIS
        Splits an install command string into primary and fallback candidates.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$InstallCommand
    )

    if ([string]::IsNullOrWhiteSpace($InstallCommand)) {
        return @()
    }

    if ($InstallCommand -notmatch '\(or:') {
        return @($InstallCommand.Trim())
    }

    $candidates = [System.Collections.Generic.List[string]]::new()
    $primary = ($InstallCommand -split '\s*\(or:\s*', 2)[0].Trim()
    if ($primary) {
        $null = $candidates.Add($primary)
    }

    foreach ($match in [regex]::Matches($InstallCommand, '\(or:\s*([^)]+)\)')) {
        $part = $match.Groups[1].Value.Trim().TrimEnd(')')
        if ($part) {
            $null = $candidates.Add($part)
        }
    }

    return @($candidates | Select-Object -Unique)
}

function Resolve-TestNodePackageInstallCommand {
    <#
    .SYNOPSIS
        Resolves a platform-aware install command for one or more Node.js packages.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string[]]$PackageNames,

        [switch]$Global
    )

    if (Get-Command Get-NodePackageInstallRecommendation -ErrorAction SilentlyContinue) {
        try {
            $recommendation = Get-NodePackageInstallRecommendation -PackageNames $PackageNames -Global:$Global
            if ($recommendation -match '^Install with:\s*(.+)$') {
                return $matches[1].Trim()
            }
            if ($recommendation) {
                return $recommendation.Trim()
            }
        }
        catch {
            # Fall through to template-based resolution when recommendation helpers fail
        }
    }

    if (@($PackageNames).Count -eq 1) {
        return Resolve-TestToolInstallCommand -ToolName $PackageNames[0] -ToolType 'node-package'
    }

    $template = Resolve-TestToolInstallCommand -ToolName $PackageNames[0] -ToolType 'node-package'
    if ($template -match '^(pnpm add -g|npm install -g|yarn global add|bun add -g)\s+') {
        return "$($matches[1]) $($PackageNames -join ' ')"
    }

    $commands = foreach ($packageName in $PackageNames) {
        Resolve-TestToolInstallCommand -ToolName $packageName -ToolType 'node-package'
    }
    return (@($commands | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique) -join ' and ')
}

function Get-TestMissingToolOutput {
    <#
    .SYNOPSIS
        Combines captured stream output with collected missing-tool warnings.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowEmptyString()]
        [string]$Output
    )

    $outputCandidates = @($Output)

    if ($global:CollectedMissingToolWarnings -and @($global:CollectedMissingToolWarnings).Count -gt 0) {
        foreach ($entry in $global:CollectedMissingToolWarnings) {
            $entryOutput = if ($entry.Message) {
                $entry.Message
            }
            elseif ($entry.InstallHint) {
                "$($entry.Tool) not found. $($entry.InstallHint)"
            }
            else {
                "$($entry.Tool) not found."
            }

            if (-not [string]::IsNullOrWhiteSpace($entryOutput)) {
                $outputCandidates += $entryOutput
            }
        }
    }

    return ($outputCandidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique) -join "`n"
}

function Initialize-ContainerEngineAvailabilityMocks {
    <#
    .SYNOPSIS
        Configures per-command availability mocks for container engine tests.
    #>
    [CmdletBinding()]
    param(
        [hashtable]$Availability,

        [switch]$MockDockerBinary,

        [switch]$MockPodmanBinary
    )

    $engineCommands = @('docker', 'docker-compose', 'podman', 'podman-compose')

    if (Get-Variable -Name '__ContainerEnginePreference' -Scope Script -ErrorAction SilentlyContinue) {
        Remove-Variable -Name '__ContainerEnginePreference' -Scope Script -Force -ErrorAction SilentlyContinue
    }

    if (Get-Variable -Name '__ContainerEngineInfo' -Scope Script -ErrorAction SilentlyContinue) {
        Remove-Variable -Name '__ContainerEngineInfo' -Scope Script -Force -ErrorAction SilentlyContinue
    }

    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }

    foreach ($commandName in $engineCommands) {
        $isAvailable = $false
        if ($null -ne $Availability) {
            if ($Availability.ContainsKey($commandName)) {
                $isAvailable = [bool]$Availability[$commandName]
            }
            elseif ($Availability.ContainsKey($commandName.ToLowerInvariant())) {
                $isAvailable = [bool]$Availability[$commandName.ToLowerInvariant()]
            }
        }

        Mock-CommandAvailabilityPester -CommandName $commandName -Available $isAvailable
    }

    if (Get-Command Mock -ErrorAction SilentlyContinue) {
        if ($MockDockerBinary -or ($null -ne $Availability -and -not [bool]$Availability['docker'])) {
            Mock -CommandName docker -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $global:LASTEXITCODE = 1
                Write-Output ''
            }
        }

        if ($MockPodmanBinary -or ($null -ne $Availability -and -not [bool]$Availability['podman'])) {
            Mock -CommandName podman -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $global:LASTEXITCODE = 1
                Write-Output ''
            }
        }
    }
}

function Initialize-ContainerEngineUnavailableMocks {
    <#
    .SYNOPSIS
        Mocks docker and podman as unavailable for container engine tests.
    #>
    [CmdletBinding()]
    param()

    Initialize-ContainerEngineAvailabilityMocks -Availability @{
        docker           = $false
        'docker-compose' = $false
        podman           = $false
        'podman-compose' = $false
    } -MockDockerBinary -MockPodmanBinary
}

function Assert-ProfileShadowedAlias {
    <#
    .SYNOPSIS
        Asserts a profile alias exists, or the target function exists when the alias name is taken on PATH.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AliasName,

        [Parameter(Mandatory)]
        [string]$FunctionName
    )

    $alias = Get-Alias -Name $AliasName -ErrorAction SilentlyContinue
    if ($alias -and $alias.ResolvedCommandName -eq $FunctionName) {
        return
    }

    $existing = Get-Command -Name $AliasName -ErrorAction SilentlyContinue
    if ($existing -and -not ($existing.CommandType -eq 'Function' -and $existing.Name -eq $FunctionName)) {
        $target = Get-Command -Name $FunctionName -CommandType Function -ErrorAction SilentlyContinue
        if (-not $target) {
            $target = Get-Command -Name $FunctionName -Scope Global -CommandType Function -ErrorAction SilentlyContinue
        }
        if (-not $target) {
            Set-ItResult -Inconclusive -Because "$AliasName is shadowed and $FunctionName is not visible in this test scope"
            return
        }
        return
    }

    $alias | Should -Not -BeNullOrEmpty
    $alias.ResolvedCommandName | Should -Be $FunctionName
}

function Assert-ProfileCommandAlias {
    <#
    .SYNOPSIS
        Asserts a profile alias exists or the target function is available when the alias name is taken by an external command.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AliasName,

        [Parameter(Mandatory)]
        [string]$FunctionName
    )

    $alias = Get-Alias -Name $AliasName -ErrorAction SilentlyContinue
    if ($alias -and $alias.ResolvedCommandName -eq $FunctionName) {
        return
    }

    $external = Get-Command -Name $AliasName -CommandType Application -ErrorAction SilentlyContinue
    if ($external) {
        $target = Get-Command -Name $FunctionName -CommandType Function -ErrorAction SilentlyContinue
        if (-not $target) {
            $target = Get-Command -Name $FunctionName -Scope Global -CommandType Function -ErrorAction SilentlyContinue
        }
        $target | Should -Not -BeNullOrEmpty
        return
    }

    $alias | Should -Not -BeNullOrEmpty
    $alias.ResolvedCommandName | Should -Be $FunctionName
}

function Assert-ProfileCommandAliasOrShadowed {
    <#
    .SYNOPSIS
        Like Assert-ProfileCommandAlias but marks inconclusive when the alias name is taken by a non-profile command that is not an Application (e.g. cmdlet).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AliasName,

        [Parameter(Mandatory)]
        [string]$FunctionName
    )

    $alias = Get-Alias -Name $AliasName -ErrorAction SilentlyContinue
    if ($alias -and $alias.ResolvedCommandName -eq $FunctionName) {
        return
    }

    $externalApp = Get-Command -Name $AliasName -CommandType Application -ErrorAction SilentlyContinue
    if ($externalApp) {
        Assert-ProfileCommandAlias -AliasName $AliasName -FunctionName $FunctionName
        return
    }

    $blocking = Get-Command -Name $AliasName -ErrorAction SilentlyContinue
    if ($blocking) {
        Set-ItResult -Inconclusive -Because "$AliasName is reserved by $($blocking.CommandType) on PATH and the profile alias was not registered"
        return
    }

    Assert-ProfileCommandAlias -AliasName $AliasName -FunctionName $FunctionName
}

function Assert-ModernCliWrapperDefined {
    <#
    .SYNOPSIS
        Asserts a Register-ToolWrapper function exists, or marks inconclusive when PATH shadows the name.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $wrapper = Get-Command -Name $Name -CommandType Function -ErrorAction SilentlyContinue
    if ($wrapper) {
        return
    }

    $external = Get-Command -Name $Name -CommandType Application -ErrorAction SilentlyContinue
    if ($external) {
        Set-ItResult -Inconclusive -Because "$Name binary on PATH shadows the profile wrapper"
        return
    }

    Set-ItResult -Inconclusive -Because "$Name is not installed and no profile wrapper was registered"
}

function Assert-TestMissingToolWarning {
    <#
    .SYNOPSIS
        Asserts a missing-tool message appears in output or collected warnings.
    #>
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$Output,

        [Parameter(Mandatory)]
        [string]$Pattern
    )

    if (-not [string]::IsNullOrWhiteSpace($Output) -and $Output -match $Pattern) {
        return
    }

    if ($global:CollectedMissingToolWarnings -and @($global:CollectedMissingToolWarnings).Count -gt 0) {
        foreach ($entry in $global:CollectedMissingToolWarnings) {
            $entryOutput = if ($entry.Message) {
                $entry.Message
            }
            elseif ($entry.InstallHint) {
                "$($entry.Tool) not found. $($entry.InstallHint)"
            }
            else {
                "$($entry.Tool) not found."
            }

            if (-not [string]::IsNullOrWhiteSpace($entryOutput) -and $entryOutput -match $Pattern) {
                return
            }
        }
    }

    $combined = Get-TestMissingToolOutput -Output $Output
    $combined | Should -Match $Pattern
}

function Assert-TestOutputContainsInstallCommand {
    <#
    .SYNOPSIS
        Asserts captured output includes a platform-aware install command for a tool.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Output,

        [string]$ToolName,

        [string[]]$ToolNames,

        [ValidateSet('python-package', 'node-package', 'python-runtime', 'rust-package', 'go-package', 'java-build-tool', 'ruby-package', 'php-package', 'dotnet-package', 'dart-package', 'elixir-package', 'generic')]
        [string]$ToolType = 'generic'
    )

    $names = if ($null -ne $ToolNames -and @($ToolNames).Count -gt 0) {
        @($ToolNames)
    }
    elseif (-not [string]::IsNullOrWhiteSpace($ToolName)) {
        @($ToolName)
    }
    else {
        @()
    }

    if (@($names).Count -eq 0) {
        throw 'Assert-TestOutputContainsInstallCommand requires ToolName or ToolNames.'
    }

    $matched = $false
    $outputCandidates = @($Output)

    if ($global:CollectedMissingToolWarnings -and @($global:CollectedMissingToolWarnings).Count -gt 0) {
        foreach ($entry in $global:CollectedMissingToolWarnings) {
            $entryOutput = if ($entry.Message) {
                $entry.Message
            }
            elseif ($entry.InstallHint) {
                "$($entry.Tool) not found. $($entry.InstallHint)"
            }
            else {
                "$($entry.Tool) not found."
            }

            if (-not [string]::IsNullOrWhiteSpace($entryOutput)) {
                $outputCandidates += $entryOutput
            }
        }
    }

    foreach ($outputText in ($outputCandidates | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($outputText)) {
            continue
        }

        foreach ($name in $names) {
            $installCommand = Resolve-TestToolInstallCommand -ToolName $name -ToolType $ToolType
            foreach ($candidate in (Get-TestInstallCommandCandidates -InstallCommand $installCommand)) {
                if ($outputText -match [regex]::Escape($candidate)) {
                    $matched = $true
                    break
                }
            }
            if ($matched) {
                break
            }
        }
        if ($matched) {
            break
        }
    }

    if (-not $matched) {
        $combinedOutput = Get-TestMissingToolOutput -Output $Output
        if ($combinedOutput -match 'Install with:') {
            return
        }

        $fallbackCommand = Resolve-TestToolInstallCommand -ToolName $names[0] -ToolType $ToolType
        $fallbackCandidate = (Get-TestInstallCommandCandidates -InstallCommand $fallbackCommand | Select-Object -First 1)
        if ($fallbackCandidate) {
            $combinedOutput | Should -Match ([regex]::Escape($fallbackCandidate))
        }
        else {
            $combinedOutput | Should -Match 'Install with:'
        }
    }
}

function Assert-TestNodePackageMissingError {
    <#
    .SYNOPSIS
        Asserts a Node.js package missing error includes a platform-aware install command.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,

        [string]$FullError = '',

        [Parameter(Mandatory)]
        [string[]]$PackageNames,

        [Parameter(Mandatory)]
        [string]$PackagePattern
    )

    $combinedError = "$FullError$ErrorMessage"
    if ($ErrorMessage -notmatch $PackagePattern -and $combinedError -notmatch $PackagePattern -and $ErrorMessage -notmatch 'MODULE_NOT_FOUND') {
        return
    }

    $installCommand = Resolve-TestNodePackageInstallCommand -PackageNames $PackageNames
    if ($combinedError -match [regex]::Escape($installCommand)) {
        Write-Host "Installation command found in error: $installCommand" -ForegroundColor Yellow
        $ErrorMessage | Should -Match ([regex]::Escape($installCommand))
    }
    elseif ($combinedError -match $PackagePattern) {
        Write-Host "Required packages may not be installed. Install with: $installCommand" -ForegroundColor Yellow
        $ErrorMessage | Should -Match $PackagePattern
    }
}

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
        Recommended installation command. When omitted, resolved via Resolve-TestToolInstallCommand.

    .PARAMETER ToolType
        Tool category used when resolving install commands automatically.

    .PARAMETER InstallUrl
        URL where the tool can be downloaded.

    .PARAMETER Required
        If specified, throws an error when the tool is not available.

    .PARAMETER Silent
        If specified, suppresses warning messages for missing optional tools.

    .EXAMPLE
        $result = Test-ToolAvailable -ToolName 'docker'
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

        [ValidateSet('python-package', 'node-package', 'python-runtime', 'rust-package', 'go-package', 'java-build-tool', 'ruby-package', 'php-package', 'dotnet-package', 'dart-package', 'elixir-package', 'generic')]
        [string]$ToolType = 'generic',

        [string]$InstallUrl,

        [switch]$Required,

        [switch]$Silent
    )

    if (-not $InstallCommand) {
        $InstallCommand = Resolve-TestToolInstallCommand -ToolName $ToolName -ToolType $ToolType
    }

    $resolvedName = $ToolName
    $available = Get-Command $ToolName -ErrorAction SilentlyContinue
    if (-not $available -and $ToolName -eq 'yq') {
        $available = Get-Command go-yq -ErrorAction SilentlyContinue
        if ($available) {
            $resolvedName = 'go-yq'
        }
    }

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
        Name           = $resolvedName
        Available      = [bool]$available
        Path           = if ($available) { $available.Source } else { $null }
        Required       = $Required.IsPresent
        InstallCommand = $InstallCommand
        InstallUrl     = $InstallUrl
    }
}

function Test-MikefarahYqAvailable {
    <#
    .SYNOPSIS
        Returns whether mikefarah/yq v4+ is installed (not python-yq).

    .DESCRIPTION
        Profile YAML conversions use `yq eval`, which requires
        https://github.com/mikefarah/yq. The unrelated python `yq` package
        exposes a different CLI and is not compatible.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if (Get-Command Get-CachedExternalCommand -ErrorAction SilentlyContinue) {
        $yqCmd = Get-CachedExternalCommand -Name 'yq'
        if ($yqCmd -and (Get-Command Test-IsMikefarahYqExecutable -ErrorAction SilentlyContinue)) {
            $executable = if (-not [string]::IsNullOrWhiteSpace($yqCmd.Source)) { $yqCmd.Source } else { $yqCmd.Name }
            return Test-IsMikefarahYqExecutable -Executable $executable
        }
    }

    foreach ($candidate in @('go-yq', 'yq')) {
        $cmd = Get-Command $candidate -CommandType Application -ErrorAction SilentlyContinue
        if (-not $cmd) {
            continue
        }

        $exe = $cmd.Source
        if (Get-Command Test-IsMikefarahYqExecutable -ErrorAction SilentlyContinue) {
            if (Test-IsMikefarahYqExecutable -Executable $exe) {
                return $true
            }
        }
        else {
            $versionOutput = (& $exe --version 2>&1 | Out-String).Trim()
            if ($versionOutput -match 'mikefarah|github\.com/mikefarah') {
                return $true
            }

            if ($versionOutput -notmatch '^yq\s+\d') {
                $evalHelp = (& $exe eval --help 2>&1 | Out-String)
                if ($evalHelp -match 'evaluates' -and $evalHelp -notmatch 'jq_filter') {
                    return $true
                }
            }
        }
    }

    return $false
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

    $tools = @(
        @{ Name = 'docker'; InstallUrl = 'https://www.docker.com/get-started'; ToolType = 'generic' }
        @{ Name = 'podman'; InstallUrl = 'https://podman.io/getting-started/installation'; ToolType = 'generic' }
        @{ Name = 'git'; InstallUrl = 'https://git-scm.com/downloads'; ToolType = 'generic' }
        @{ Name = 'kubectl'; InstallUrl = 'https://kubernetes.io/docs/tasks/tools/'; ToolType = 'generic' }
        @{ Name = 'terraform'; InstallUrl = 'https://www.terraform.io/downloads'; ToolType = 'generic' }
        @{ Name = 'aws'; InstallUrl = 'https://aws.amazon.com/cli/'; ToolType = 'generic' }
        @{ Name = 'az'; InstallUrl = 'https://docs.microsoft.com/en-us/cli/azure/install-azure-cli'; ToolType = 'generic' }
        @{ Name = 'gcloud'; InstallUrl = 'https://cloud.google.com/sdk/docs/install'; ToolType = 'generic' }
        @{ Name = 'oh-my-posh'; InstallUrl = 'https://ohmyposh.dev/docs/installation'; ToolType = 'generic' }
        @{ Name = 'starship'; InstallUrl = 'https://starship.rs/guide/#%F0%9F%9A%80-installation'; ToolType = 'generic' }
        @{ Name = 'bat'; InstallUrl = 'https://github.com/sharkdp/bat'; ToolType = 'generic' }
        @{ Name = 'fd'; InstallUrl = 'https://github.com/sharkdp/fd'; ToolType = 'generic' }
        @{ Name = 'http'; InstallUrl = 'https://httpie.io/'; ToolType = 'generic' }
        @{ Name = 'zoxide'; InstallUrl = 'https://github.com/ajeetdsouza/zoxide'; ToolType = 'generic' }
        @{ Name = 'delta'; InstallUrl = 'https://github.com/dandavison/delta'; ToolType = 'generic' }
        @{ Name = 'tldr'; InstallUrl = 'https://tldr.sh/'; ToolType = 'generic' }
        @{ Name = 'procs'; InstallUrl = 'https://github.com/dalance/procs'; ToolType = 'generic' }
        @{ Name = 'dust'; InstallUrl = 'https://github.com/bootandy/dust'; ToolType = 'generic' }
        @{ Name = 'ssh'; InstallUrl = 'https://www.openssh.com/'; ToolType = 'generic' }
        @{ Name = 'ansible'; InstallUrl = 'https://docs.ansible.com/ansible/latest/installation_guide/index.html'; ToolType = 'python-package' }
        @{ Name = 'gh'; InstallUrl = 'https://cli.github.com/'; ToolType = 'generic' }
        @{ Name = 'wsl'; InstallUrl = 'https://docs.microsoft.com/en-us/windows/wsl/install'; ToolType = 'generic' }
        @{ Name = 'pnpm'; InstallUrl = 'https://pnpm.io/installation'; ToolType = 'node-package' }
        @{ Name = 'uv'; InstallUrl = 'https://github.com/astral-sh/uv'; ToolType = 'python-package' }
    )

    $results = @()
    foreach ($tool in $tools) {
        $installCommand = Resolve-TestToolInstallCommand -ToolName $tool.Name -ToolType $tool.ToolType

        $result = Test-ToolAvailable `
            -ToolName $tool.Name `
            -InstallCommand $installCommand `
            -ToolType $tool.ToolType `
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
