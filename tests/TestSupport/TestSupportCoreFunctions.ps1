# ===============================================
# TestSupportCoreFunctions.ps1
# Canonical TestSupport helpers restored between test files
# ===============================================

$script:SavedStructuredLoggingFunctions = @{}

function Enable-TestStructuredLogging {
    <#
    .SYNOPSIS
        Installs lightweight structured-logging stubs for unit tests.

    .DESCRIPTION
        Provides no-op Write-StructuredWarning and Write-StructuredError functions
        without dot-sourcing profile bootstrap fragments. Avoids Set-AgentModeFunction
        load failures and JSON warning noise during combined Pester coverage runs.
    #>
    [CmdletBinding()]
    param()

    foreach ($name in @('Write-StructuredWarning', 'Write-StructuredError', 'Write-WideEvent')) {
        if (-not $script:SavedStructuredLoggingFunctions.ContainsKey($name)) {
            $existing = Get-Command $name -ErrorAction SilentlyContinue
            if ($existing -and $existing.CommandType -eq 'Function') {
                $script:SavedStructuredLoggingFunctions[$name] = $existing.ScriptBlock
            }
        }
    }

    function global:Write-StructuredWarning {
        [CmdletBinding()]
        param(
            [string]$Message,
            [string]$OperationName,
            [hashtable]$Context,
            [string]$Code
        )
    }

    function global:Write-StructuredError {
        [CmdletBinding()]
        param(
            [object]$ErrorRecord,
            [string]$Message,
            [string]$OperationName,
            [hashtable]$Context,
            [string]$Code
        )
    }

    function global:Write-WideEvent {
        [CmdletBinding()]
        param(
            [string]$EventName,
            [hashtable]$Data
        )
    }
}

function Disable-TestStructuredLogging {
    <#
    .SYNOPSIS
        Removes structured-logging test stubs from the session.
    #>
    [CmdletBinding()]
    param()

    Remove-TestFunction -Name 'Write-StructuredWarning', 'Write-StructuredError', 'Write-WideEvent'

    foreach ($entry in $script:SavedStructuredLoggingFunctions.GetEnumerator()) {
        Set-Item -Path "Function:\global:$($entry.Key)" -Value $entry.Value -Force -ErrorAction SilentlyContinue
    }

    $script:SavedStructuredLoggingFunctions = @{}
}

function Remove-TestFunction {
    <#
    .SYNOPSIS
        Removes a test stub function from both session and global function drives.

    .DESCRIPTION
        PowerShell can expose the same global function as Function:\Name and
        Function:\global:Name. Removing only one path leaves a leaked stub that
        pollutes later tests in combined Pester runs.

    .PARAMETER Name
        Function name(s) to remove.

    .EXAMPLE
        Remove-TestFunction -Name 'Test-ValidString'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Name
    )

    process {
        foreach ($functionName in $Name) {
            if ([string]::IsNullOrWhiteSpace($functionName)) {
                continue
            }

            Remove-Item -Path "Function:\$functionName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$functionName" -Force -ErrorAction SilentlyContinue
        }
    }
}

function Mark-TestCommandsUnavailable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$CommandNames
    )

    foreach ($command in $CommandNames) {
        if (Get-Command Set-TestCommandAvailabilityState -ErrorAction SilentlyContinue) {
            Set-TestCommandAvailabilityState -CommandName $command -Available $false
            continue
        }

        if (-not (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue)) {
            $global:TestCachedCommandCache = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()
        }

        if (-not (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue)) {
            $global:AssumedAvailableCommands = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
        }

        Remove-TestFunction -Name $command
        Remove-Item -Path "Alias:\$command" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\global:$command" -Force -ErrorAction SilentlyContinue

        $removed = $null
        $null = $global:AssumedAvailableCommands.TryRemove($command, [ref]$removed)

        $cacheKey = $command.ToLowerInvariant()
        $global:TestCachedCommandCache[$cacheKey] = [pscustomobject]@{
            Result  = $false
            Expires = (Get-Date).AddHours(24)
        }
    }
}

function Register-TestFragmentAliases {
    <#
    .SYNOPSIS
        Force-registers profile aliases when host binaries would shadow Set-AgentModeAlias.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$AliasTargets
    )

    foreach ($entry in $AliasTargets.GetEnumerator()) {
        if (Get-Command $entry.Value -CommandType Function -ErrorAction SilentlyContinue) {
            Set-Alias -Name $entry.Key -Value $entry.Value -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
}

function Import-ProfileFragmentWithShadowedCommands {
    <#
    .SYNOPSIS
        Loads a profile fragment after hiding host commands that would shadow aliases.

    .DESCRIPTION
        Removes aliases/functions for the given command names, marks them unavailable
        in the test command cache, dot-sources the fragment, then force-registers aliases
        when host binaries would otherwise prevent Set-AgentModeAlias from succeeding.

    .PARAMETER FragmentPath
        Path to the profile fragment to load.

    .PARAMETER ShadowCommandNames
        Command names to hide before loading the fragment.

    .PARAMETER AliasTargets
        Optional map of alias name to profile function for force-registration after load.

    .PARAMETER FragmentName
        Optional fragment idempotency name to clear before reload.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FragmentPath,

        [Parameter(Mandatory)]
        [string[]]$ShadowCommandNames,

        [hashtable]$AliasTargets,

        [string]$FragmentName
    )

    Mark-TestCommandsUnavailable -CommandNames $ShadowCommandNames

    if ($FragmentName -and (Get-Command Clear-FragmentLoaded -ErrorAction SilentlyContinue)) {
        Clear-FragmentLoaded -FragmentName $FragmentName -ErrorAction SilentlyContinue
    }

    . $FragmentPath

    if ($AliasTargets) {
        foreach ($entry in $AliasTargets.GetEnumerator()) {
            if (Get-Command $entry.Value -CommandType Function -ErrorAction SilentlyContinue) {
                Set-Alias -Name $entry.Key -Value $entry.Value -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }
}

function Import-TestLibraryModule {
    <#
    .SYNOPSIS
        Imports a library module into the global session for Pester-safe visibility.

    .DESCRIPTION
        Pester loads test modules in a local scope. Importing library dependencies
        globally keeps helper commands such as Get-CachedValue visible inside modules
        under test during combined runs.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [switch]$RemoveExisting
    )

    if ($RemoveExisting -and $ModulePath) {
        $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($ModulePath)
        if (-not [string]::IsNullOrWhiteSpace($moduleName)) {
            Remove-Module -Name $moduleName -ErrorAction SilentlyContinue -Force
        }
    }

    Import-Module -Name $ModulePath -DisableNameChecking -Global -Force -ErrorAction Stop
}

function Export-TestSupportGlobalFunctions {
    <#
    .SYNOPSIS
        Promotes core TestSupport helpers to the global scope for Pester parallel workers.
    #>
    [CmdletBinding()]
    param()

    $globalFunctionNames = @(
        'Get-TestSupportPath'
        'Get-TestPath'
        'Get-TestRepoRoot'
        'Get-TestSuitePath'
        'Get-TestSuiteFiles'
        'Get-TestArtifactPath'
        'Get-TestArtifactsPath'
        'Get-TestDataPath'
        'Get-TestScriptPath'
        'Get-TestRepoRelativePath'
        'Get-TestProfileDir'
        'New-TestTempDirectory'
        'New-TestExternalTempDirectory'
        'New-TestTempFile'
        'Remove-TestArtifacts'
        'Register-TestCleanupPath'
        'Clear-RegisteredTestCleanupPaths'
        'Clear-TestTransientStorage'
        'Initialize-TestCleanupRegistry'
        'Backup-TestFileBytes'
        'Restore-TestFileBytes'
        'Write-TestFileLiteralContent'
        'Import-TestLibraryModule'
        'Initialize-TestProfile'
        'Reset-TestIsolationState'
        'Restore-TestSupportHelperFunctions'
        'Restore-TestSupportFunctions'
        'Get-PythonPackageInstallRecommendation'
        'Invoke-MakeGenericTypeWrapper'
        'Invoke-CreateInstanceWrapper'
        'Invoke-TypeConstructorWrapper'
        'Invoke-TestPwshScript'
        'Invoke-TestScriptFile'
        'Initialize-ConversionIntegrationForTestFile'
        'Initialize-ConversionIntegration'
        'Enable-TestStructuredLogging'
        'Disable-TestStructuredLogging'
        'Remove-TestFunction'
        'Setup-CapturingCommandMock'
        'Mock-EnvironmentVariable'
        'Restore-EnvironmentVariable'
    )

    foreach ($functionName in $globalFunctionNames) {
        $command = Get-Command $functionName -ErrorAction SilentlyContinue
        if (-not $command) {
            continue
        }

        if ($command.CommandType -ne 'Function') {
            continue
        }

        Set-Item -Path "Function:\global:$functionName" -Value $command.ScriptBlock -Force
    }
}

function Restore-TestSupportHelperFunctions {
    <#
    .SYNOPSIS
        Re-registers TestSupport helper functions cleared by Reset-TestIsolationState.
    #>
    [CmdletBinding()]
    param()

    $helperFiles = @(
        'TestSupportCoreFunctions.ps1'
        'TestPaths.ps1'
        'TestExecution.ps1'
        'TestPythonHelpers.ps1'
        'TestReflectionHelpers.ps1'
    )

    foreach ($helperFile in $helperFiles) {
        $helperPath = Join-Path $PSScriptRoot $helperFile
        if (Test-Path -LiteralPath $helperPath) {
            . $helperPath
        }
    }
}

function Clear-CommandTestStubs {
    <#
    .SYNOPSIS
        Removes command-module test stubs that leak across combined Pester runs.
    #>
    [CmdletBinding()]
    param()

    Remove-TestFunction -Name @(
        'Test-CachedCommand'
        'Test-ValidString'
        'Get-PreferenceAwareInstallHint'
        'Get-PythonPackageInstallRecommendation'
        'Get-NodePackageInstallRecommendation'
        'Get-Platform'
        'Import-Requirements'
        'CommandFailureProbe'
        'Import-ModuleSafely'
        'Test-FailingCommand'
        'Test-ThrowingCommand'
        'Test-ThrowingCommand2'
        'Read-FileContent'
    )
}

function Clear-CollectionsWrapperStubs {
    <#
    .SYNOPSIS
        Removes Collections reflection wrapper stubs created during unit tests.
    #>
    [CmdletBinding()]
    param()

    Remove-TestFunction -Name @(
        'Invoke-MakeGenericTypeWrapper'
        'Invoke-CreateInstanceWrapper'
        'Invoke-TypeConstructorWrapper'
    )
}

function Clear-DispatcherTestStubs {
    <#
    .SYNOPSIS
        Removes CommandDispatcher test doubles from the global function drive.
    #>
    [CmdletBinding()]
    param()

    Remove-TestFunction -Name @(
        'Load-FragmentForCommand'
        'Invoke-WithWideEvent'
        'DispatcherExtendedTestCmd'
    )
}

function Clear-LibraryTestEnvironmentVariables {
    <#
    .SYNOPSIS
        Clears environment variables commonly mutated by library unit tests.
    #>
    [CmdletBinding()]
    param(
        [string[]]$AdditionalNames
    )

    $names = @(
        'PS_PROFILE_DEBUG'
        'PS_PROFILE_PLATFORM_FORCE_NAME'
        'PS_PROFILE_PLATFORM_FORCE_FALLBACK'
        'PS_PROFILE_PLATFORM_FORCE_OS_PLATFORM'
        'PS_PROFILE_PLATFORM_FORCE_UNAME'
        'PS_PROFILE_PLATFORM_FORCE_NATURAL_WINDOWS'
        'PS_PROFILE_PLATFORM_FORCE_NATURAL_MACOS'
        'PS_PROFILE_PLATFORM_FORCE_NATURAL_FALLBACK'
        'PS_PROFILE_PLATFORM_FORCE_LEGACY_ELSE'
        'PS_PROFILE_PLATFORM_FORCE_FINAL_ELSE'
        'PS_PROFILE_PLATFORM_PATHS_FORCE_NO_USER_HOME'
        'PS_PROFILE_PLATFORM_PATHS_FORCE_USER_HOME'
        'PS_PROFILE_PROMPT_FORCE_INIT_ERROR'
        'PS_PROFILE_COMMAND_DISABLE_STRUCTURED_WARNING'
        'PS_PROFILE_COMMAND_FORCE_CACHE_IMPORT_ERROR'
        'PS_PROFILE_COMMAND_FORCE_MANUAL_CACHE_IMPORT'
        'PS_PROFILE_COMMAND_FORCE_MANUAL_INSTALL_RESOLVE'
        'PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_WARNING'
        'PS_PROFILE_COLLECTIONS_DISABLE_STRUCTURED_ERROR'
        'PS_PROFILE_COLLECTIONS_FORCE_OBJECT_LIST_ERROR'
        'PS_PROFILE_COLLECTIONS_FORCE_MAKE_GENERIC_NULL'
        'PS_PROFILE_COLLECTIONS_FORCE_CREATE_INSTANCE_NULL'
        'PS_PROFILE_COLLECTIONS_FORCE_STRING_LIST_ERROR'
        'PS_PROFILE_COLLECTIONS_FORCE_STRING_LIST_NULL'
        'PS_PROFILE_COLLECTIONS_FORCE_TYPED_LIST_ERROR'
        'PS_PROFILE_COLLECTIONS_FORCE_TYPE_OBJ_NULL'
        'PS_PROFILE_COLLECTIONS_FORCE_TYPED_MAKE_GENERIC_NULL'
        'PS_PROFILE_COLLECTIONS_FORCE_TYPED_CREATE_INSTANCE_NULL'
        'PS_PROFILE_FILESYSTEM_FORCE_MKDIR_ERROR'
        'PS_PROFILE_FILESYSTEM_FORCE_UNAUTHORIZED_ACCESS'
        'PS_PROFILE_FILESYSTEM_FORCE_GET_CHILD_ERROR'
        'PS_PROFILE_AUTO_LOAD_FRAGMENTS'
        'PS_PROFILE_AUTO_LOAD_TIMEOUT'
        'XDG_CONFIG_HOME'
        'XDG_DATA_HOME'
        'XDG_DOWNLOAD_DIR'
        'APPDATA'
        'PYTHON'
        'PYTHON_HOME'
        'PYTHON_ROOT'
        'VIRTUAL_ENV'
        'CONDA_PREFIX'
        'PS_PYTHON_RUNTIME'
        'PS_DATA_FRAME_LIB'
        'PS_PYTHON_PACKAGE_MANAGER'
        'PS_PARQUET_LIB'
        'PS_SCIENTIFIC_LIB'
        'PNPM_HOME'
        'PNPM_ROOT'
        'NPM_CONFIG_PREFIX'
        'NODE_PATH'
        'NVM_DIR'
        'PS_NODE_PACKAGE_MANAGER'
        'PS_PROFILE_REPO_ROOT'
        'LOCALAPPDATA'
    )

    if ($AdditionalNames) {
        $names = @($names + $AdditionalNames) | Select-Object -Unique
    }

    foreach ($name in $names) {
        Remove-Item -Path "Env:$name" -ErrorAction SilentlyContinue
    }
}

function Clear-RuntimeTestGlobals {
    <#
    .SYNOPSIS
        Clears global state mutated by Python and NodeJs runtime unit tests.
    #>
    [CmdletBinding()]
    param()

    $global:BinaryConversionBasePath = $null

    if (Get-Command Mark-TestCommandsUnavailable -ErrorAction SilentlyContinue) {
        Mark-TestCommandsUnavailable -CommandNames @(
            'python', 'python3', 'py', 'pip', 'uv', 'conda', 'poetry', 'pipenv',
            'pnpm', 'npm', 'node', 'yarn', 'bun'
        )
    }
}

function Reset-TestLibraryModule {
    <#
    .SYNOPSIS
        Reimports a library module globally for isolated test resets.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath
    )

    Import-TestLibraryModule -ModulePath $ModulePath -RemoveExisting
}
