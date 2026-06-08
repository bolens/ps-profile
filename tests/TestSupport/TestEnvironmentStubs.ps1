# ===============================================
# TestEnvironmentStubs.ps1
# Environment variable stubs with automatic cleanup
# ===============================================

$script:MockRegistry = @{
    Functions = @{}
    Commands  = @{}
    Variables = @{}
    Original  = @{}
}

function Register-Mock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Function', 'Command', 'Variable')]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$MockValue,

        [object]$Original = $null
    )

    $registryKey = switch ($Type) {
        'Function' { 'Functions' }
        'Command' { 'Commands' }
        'Variable' { 'Variables' }
        default { $Type }
    }

    $key = "$Type`:$Name"
    $script:MockRegistry[$registryKey][$Name] = @{
        MockValue  = $MockValue
        Original   = $Original
        Registered = Get-Date
    }

    if ($Original) {
        $script:MockRegistry.Original[$key] = $Original
    }
}

function Clear-MockRegistry {
    [CmdletBinding()]
    param()

    $script:MockRegistry.Functions.Clear()
    $script:MockRegistry.Commands.Clear()
    $script:MockRegistry.Variables.Clear()
    $script:MockRegistry.Original.Clear()
}

function Restore-AllMocks {
    [CmdletBinding()]
    param()

    foreach ($name in $script:MockRegistry.Functions.Keys) {
        $mock = $script:MockRegistry.Functions[$name]
        if ($mock.Original) {
            if (Test-Path "Function:\$name") {
                Set-Item -Path "Function:\$name" -Value $mock.Original -Force -ErrorAction SilentlyContinue
            }
            elseif ($mock.Original -is [scriptblock]) {
                Set-Item -Path "Function:\$name" -Value $mock.Original -Force -ErrorAction SilentlyContinue
            }
        }
        else {
            Remove-Item -Path "Function:\$name" -Force -ErrorAction SilentlyContinue
        }
    }

    foreach ($name in $script:MockRegistry.Variables.Keys) {
        $mock = $script:MockRegistry.Variables[$name]
        if ($mock.Original) {
            Set-Variable -Name $name -Value $mock.Original -Scope Global -Force -ErrorAction SilentlyContinue
        }
        else {
            Remove-Variable -Name $name -Scope Global -Force -ErrorAction SilentlyContinue
        }
    }

    Clear-MockRegistry
}

function Get-MockRegistry {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return $script:MockRegistry
}

function Mock-EnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Value,

        [switch]$RestoreOriginal = $true,

        [ValidateSet('It', 'Context', 'Describe', 'All')]
        [string]$Scope = 'It'
    )

    $original = [Environment]::GetEnvironmentVariable($Name, 'Process')
    if ($null -eq $original) {
        $envItem = Get-Item -Path "Env:\$Name" -ErrorAction SilentlyContinue
        if ($null -ne $envItem) {
            $original = $envItem.Value
        }
    }

    if ($null -eq $Value) {
        [Environment]::SetEnvironmentVariable($Name, $null, 'Process')
        Remove-Item -Path "Env:\$Name" -Force -ErrorAction SilentlyContinue
    }
    else {
        [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
        Set-Item -Path "Env:\$Name" -Value $Value -Force
    }

    if ($RestoreOriginal) {
        Register-Mock -Type 'Variable' -Name $Name -MockValue ([object]$Value) -Original $original
    }

    Write-Verbose "Mocked environment variable: $Name = $Value (original: $original)"
}

function Restore-EnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $key = "Variable:$Name"
    $registry = Get-MockRegistry
    if ($registry.Original.ContainsKey($key)) {
        $original = $registry.Original[$key]
        if ($null -eq $original) {
            [Environment]::SetEnvironmentVariable($Name, $null, 'Process')
            Remove-Item -Path "Env:\$Name" -Force -ErrorAction SilentlyContinue
        }
        else {
            [Environment]::SetEnvironmentVariable($Name, $original, 'Process')
            Set-Item -Path "Env:\$Name" -Value $original -Force
        }
        Write-Verbose "Restored environment variable: $Name = $original"
    }
    else {
        Write-Verbose "No original value found for environment variable: $Name"
    }
}

function Mock-EnvironmentVariables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Variables,

        [switch]$RestoreOriginal = $true
    )

    foreach ($name in $Variables.Keys) {
        Mock-EnvironmentVariable -Name $name -Value $Variables[$name] -RestoreOriginal:$RestoreOriginal
    }
}
