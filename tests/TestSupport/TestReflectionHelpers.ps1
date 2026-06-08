# ===============================================
# TestReflectionHelpers.ps1
# Reflection wrappers for testing .NET static method error paths
# ===============================================

function Invoke-MakeGenericTypeWrapper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [type]$GenericTypeDefinition,

        [Parameter(Mandatory)]
        [type[]]$TypeArguments,

        [switch]$ForceNull,

        [switch]$ForceException
    )

    if ($ForceException) {
        throw [System.InvalidOperationException]::new('Mocked exception for testing')
    }

    if ($ForceNull) {
        return $null
    }

    return $GenericTypeDefinition.MakeGenericType($TypeArguments)
}

function Invoke-CreateInstanceWrapper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [type]$Type,

        [switch]$ForceNull,

        [switch]$ForceException
    )

    if ($ForceException) {
        throw [System.InvalidOperationException]::new('Mocked exception for testing')
    }

    if ($ForceNull) {
        return $null
    }

    return [System.Activator]::CreateInstance($Type)
}

function Invoke-TypeConstructorWrapper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [type]$Type,

        [switch]$ForceNull,

        [switch]$ForceException
    )

    if ($ForceException) {
        throw [System.InvalidOperationException]::new('Mocked exception for testing')
    }

    if ($ForceNull) {
        return $null
    }

    return $Type::new()
}

if (-not (Get-Command Invoke-MakeGenericTypeWrapper -ErrorAction SilentlyContinue -Scope Global)) {
    Set-Item -Path Function:\global:Invoke-MakeGenericTypeWrapper -Value ${function:Invoke-MakeGenericTypeWrapper} -Force
}
if (-not (Get-Command Invoke-CreateInstanceWrapper -ErrorAction SilentlyContinue -Scope Global)) {
    Set-Item -Path Function:\global:Invoke-CreateInstanceWrapper -Value ${function:Invoke-CreateInstanceWrapper} -Force
}
if (-not (Get-Command Invoke-TypeConstructorWrapper -ErrorAction SilentlyContinue -Scope Global)) {
    Set-Item -Path Function:\global:Invoke-TypeConstructorWrapper -Value ${function:Invoke-TypeConstructorWrapper} -Force
}
