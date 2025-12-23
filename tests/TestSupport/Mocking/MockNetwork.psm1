# ===============================================
# MockNetwork.psm1
# Network mocking utilities
# ===============================================

<#
.SYNOPSIS
    Network mocking utilities.

.DESCRIPTION
    Provides functions for mocking network-related cmdlets like Invoke-WebRequest, Invoke-RestMethod,
    Test-Connection, Resolve-DnsName, etc. with full Pester 5 integration.
#>

# Import mock registry and Pester mock functions
$modulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $modulePath 'MockRegistry.psm1') -DisableNameChecking -ErrorAction Stop
Import-Module (Join-Path $modulePath 'PesterMocks.psm1') -DisableNameChecking -ErrorAction Stop

<#
.SYNOPSIS
    Mocks network operations using Pester 5.

.DESCRIPTION
    Provides easy mocking of network-related cmdlets using Pester 5's Mock command.
    This is the recommended approach for network mocking in tests.

.PARAMETER Operation
    Network operation to mock: Invoke-WebRequest, Invoke-RestMethod, Test-Connection, Resolve-DnsName, or netstat.

.PARAMETER MockWith
    ScriptBlock to execute when the operation is called.

.PARAMETER ReturnValue
    Simple return value (creates a mock that returns this value).

.PARAMETER ParameterFilter
    Pester 5 parameter filter scriptblock.

.PARAMETER Scope
    Pester 5 scope: 'It', 'Context', 'Describe', or 'All'. Default is 'It'.

.PARAMETER Times
    Number of times the mock should be called.

.PARAMETER Exactly
    If true, mock must be called exactly the specified number of times.

.EXAMPLE
    Mock-NetworkPester -Operation 'Test-Connection' -ReturnValue @{
        ComputerName = 'localhost'
        ResponseTime = 1
        Status = 'Success'
    }

.EXAMPLE
    Mock-NetworkPester -Operation 'Invoke-WebRequest' -MockWith {
        [PSCustomObject]@{ StatusCode = 200; Content = 'Success'; Headers = @{} }
    } -ParameterFilter { $Uri -eq 'https://example.com' }

.EXAMPLE
    Mock-NetworkPester -Operation 'Invoke-RestMethod' -ReturnValue @{ data = 'test' } -Scope Context
#>
function Mock-NetworkPester {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Invoke-WebRequest', 'Invoke-RestMethod', 'Test-Connection', 'Resolve-DnsName', 'netstat')]
        [string]$Operation,

        [scriptblock]$MockWith,

        [object]$ReturnValue,

        [scriptblock]$ParameterFilter,

        [ValidateSet('It', 'Context', 'Describe', 'All')]
        [string]$Scope = 'It',

        [int]$Times,

        [switch]$Exactly
    )

    # Check if Mock is available
    if (-not (Get-Command Mock -ErrorAction SilentlyContinue)) {
        Write-Warning "Pester Mock command not available. Install Pester 5 module."
        return
    }

    $params = @{
        CommandName = $Operation
    }

    if ($MockWith) {
        $params['MockWith'] = $MockWith
    }
    elseif ($null -ne $ReturnValue) {
        # Create scriptblock that returns the value directly
        # Use a scriptblock factory pattern to capture the value
        $returnValueCopy = $ReturnValue
        $params['MockWith'] = {
            param()
            $returnValueCopy
        }.GetNewClosure()
    }
    else {
        # Default mock that returns success
        $params['MockWith'] = switch ($Operation) {
            'Invoke-WebRequest' {
                { [PSCustomObject]@{ StatusCode = 200; Content = ''; Headers = @{} } }
            }
            'Invoke-RestMethod' {
                { @{} }
            }
            'Test-Connection' {
                { [PSCustomObject]@{ ComputerName = 'localhost'; ResponseTime = 1; Status = 'Success' } }
            }
            'Resolve-DnsName' {
                { [PSCustomObject]@{ Name = 'localhost'; Type = 'A'; IPAddress = '127.0.0.1' } }
            }
            'netstat' {
                { "Active Connections" }
            }
        }
    }

    if ($ParameterFilter) {
        $params['ParameterFilter'] = $ParameterFilter
    }

    if ($Times -gt 0) {
        $params['Times'] = $Times
        if ($Exactly) {
            $params['Exactly'] = $true
        }
    }

    # Pester 5 automatically scopes mocks based on where they're called (It, Context, Describe blocks)
    # Scope parameter is not needed - mocks are automatically scoped to the current block
    # Build Mock call with explicit parameters to ensure they're passed correctly
    $mockParams = @{
        CommandName = $Operation
        MockWith    = $params['MockWith']
    }
    
    if ($ParameterFilter) {
        $mockParams['ParameterFilter'] = $ParameterFilter
    }
    
    if ($Times -gt 0) {
        $mockParams['Times'] = $Times
        if ($Exactly) {
            $mockParams['Exactly'] = $true
        }
    }
    
    # Pester 5 automatically scopes mocks based on where they're called (It, Context, Describe blocks)
    # Call Mock directly - it will be scoped to the test block that calls this function
    Mock @mockParams
}

<#
.SYNOPSIS
    Mocks Invoke-WebRequest with common success patterns.

.DESCRIPTION
    Convenience function for mocking Invoke-WebRequest with common success responses.

.PARAMETER Uri
    URI filter (optional). If provided, mock only applies to this URI.

.PARAMETER StatusCode
    HTTP status code. Default is 200.

.PARAMETER Content
    Response content. Default is empty string.

.PARAMETER Headers
    Response headers hashtable. Default is empty.

.PARAMETER Scope
    Pester 5 scope. Default is 'It'.

.EXAMPLE
    Mock-WebRequestSuccess -Uri 'https://api.example.com/data' -Content '{"result": "success"}'
#>
function Mock-WebRequestSuccess {
    [CmdletBinding()]
    param(
        [string]$Uri,

        [int]$StatusCode = 200,

        [string]$Content = '',

        [hashtable]$Headers = @{},

        [ValidateSet('It', 'Context', 'Describe', 'All')]
        [string]$Scope = 'It'
    )

    # Check if Mock is available
    if (-not (Get-Command Mock -ErrorAction SilentlyContinue)) {
        Write-Warning "Pester Mock command not available. Install Pester 5 module."
        return
    }

    # Serialize values to JSON and embed them directly in the scriptblock
    # This avoids closure and scoping issues
    $valuesJson = (@{
            StatusCode = $StatusCode
            Content    = $Content
            Headers    = $Headers
        } | ConvertTo-Json -Compress -Depth 10)
    $escapedJson = $valuesJson -replace "'", "''"

    # Build parameters for Mock
    $mockParams = @{
        CommandName = 'Invoke-WebRequest'
        MockWith    = [scriptblock]::Create("`$values = ('$escapedJson' | ConvertFrom-Json); [PSCustomObject]@{ StatusCode = `$values.StatusCode; Content = `$values.Content; Headers = `$values.Headers }")
    }

    if ($Uri) {
        $capturedUri = $Uri
        $mockParams['ParameterFilter'] = { $Uri -eq $capturedUri }
    }

    # Pester 5 automatically scopes mocks based on where they're called (It, Context, Describe blocks)
    # Call Mock directly - it will be scoped to the test block that calls this function
    Mock @mockParams
}

<#
.SYNOPSIS
    Mocks Invoke-WebRequest to throw an error.

.DESCRIPTION
    Convenience function for mocking Invoke-WebRequest failures.

.PARAMETER Uri
    URI filter (optional).

.PARAMETER ErrorMessage
    Error message to throw. Default is generic network error.

.PARAMETER StatusCode
    HTTP status code for the error (if applicable).

.PARAMETER Scope
    Pester 5 scope. Default is 'It'.

.EXAMPLE
    Mock-WebRequestFailure -Uri 'https://invalid.com' -ErrorMessage 'Connection failed'
#>
function Mock-WebRequestFailure {
    [CmdletBinding()]
    param(
        [string]$Uri,

        [string]$ErrorMessage = 'Unable to connect to the remote server',

        [int]$StatusCode = 0,

        [ValidateSet('It', 'Context', 'Describe', 'All')]
        [string]$Scope = 'It'
    )

    # Capture variables for use in scriptblock closure
    $capturedErrorMessage = $ErrorMessage
    $capturedStatusCode = $StatusCode

    $mockWith = {
        $exception = [System.Net.WebException]::new($capturedErrorMessage)
        if ($capturedStatusCode -gt 0) {
            $response = [System.Net.HttpWebResponse]::new()
            $response.StatusCode = $capturedStatusCode
            $exception.Response = $response
        }
        throw $exception
    }

    if ($Uri) {
        $capturedUri = $Uri
        Mock-NetworkPester -Operation 'Invoke-WebRequest' -MockWith $mockWith -ParameterFilter { $Uri -eq $capturedUri }
    }
    else {
        # No URI filter - mock applies to all Invoke-WebRequest calls
        Mock-NetworkPester -Operation 'Invoke-WebRequest' -MockWith $mockWith
    }
}

<#
.SYNOPSIS
    Mocks Invoke-RestMethod with common success patterns.

.DESCRIPTION
    Convenience function for mocking Invoke-RestMethod with common success responses.

.PARAMETER Uri
    URI filter (optional).

.PARAMETER ReturnValue
    Value to return. Default is empty hashtable.

.PARAMETER Scope
    Pester 5 scope. Default is 'It'.

.EXAMPLE
    Mock-RestMethodSuccess -Uri 'https://api.example.com/data' -ReturnValue @{ data = 'test' }
#>
function Mock-RestMethodSuccess {
    [CmdletBinding()]
    param(
        [string]$Uri,

        [object]$ReturnValue = @{},

        [ValidateSet('It', 'Context', 'Describe', 'All')]
        [string]$Scope = 'It'
    )

    # Check if Mock is available
    if (-not (Get-Command Mock -ErrorAction SilentlyContinue)) {
        Write-Warning "Pester Mock command not available. Install Pester 5 module."
        return
    }

    # Serialize ReturnValue to JSON and embed it directly in the scriptblock
    # This avoids closure and scoping issues
    $returnValueJson = ($ReturnValue | ConvertTo-Json -Compress -Depth 10)
    $escapedJson = $returnValueJson -replace "'", "''"
    $mockWith = [scriptblock]::Create("('$escapedJson' | ConvertFrom-Json)")

    # Build parameters for Mock
    $mockParams = @{
        CommandName = 'Invoke-RestMethod'
        MockWith    = $mockWith
    }

    if ($Uri) {
        $capturedUri = $Uri
        $mockParams['ParameterFilter'] = { $Uri -eq $capturedUri }
    }

    # Pester 5 automatically scopes mocks based on where they're called (It, Context, Describe blocks)
    # Call Mock directly - it will be scoped to the test block that calls this function
    Mock @mockParams
}

<#
.SYNOPSIS
    Mocks Test-Connection with success or failure.

.DESCRIPTION
    Convenience function for mocking Test-Connection.

.PARAMETER Success
    If true, mock returns success. If false, throws error.

.PARAMETER ResponseTime
    Response time in milliseconds. Default is 1.

.PARAMETER ComputerName
    Computer name filter (optional).

.PARAMETER Scope
    Pester 5 scope. Default is 'It'.

.EXAMPLE
    Mock-TestConnection -Success $true -ResponseTime 10
#>
function Mock-TestConnection {
    [CmdletBinding()]
    param(
        [bool]$Success = $true,

        [int]$ResponseTime = 1,

        [string]$ComputerName,

        [ValidateSet('It', 'Context', 'Describe', 'All')]
        [string]$Scope = 'It'
    )

    if ($Success) {
        $returnValue = [PSCustomObject]@{
            ComputerName = if ($ComputerName) { $ComputerName } else { 'localhost' }
            ResponseTime = $ResponseTime
            Status       = 'Success'
        }
        
        if ($ComputerName) {
            $capturedComputerName = $ComputerName
            Mock-NetworkPester -Operation 'Test-Connection' -ReturnValue $returnValue -Scope $Scope -ParameterFilter { $ComputerName -eq $capturedComputerName }
        }
        else {
            Mock-NetworkPester -Operation 'Test-Connection' -ReturnValue $returnValue -Scope $Scope
        }
    }
    else {
        $mockWith = {
            throw "Connection failed"
        }
        
        if ($ComputerName) {
            $capturedComputerName = $ComputerName
            Mock-NetworkPester -Operation 'Test-Connection' -MockWith $mockWith -Scope $Scope -ParameterFilter { $ComputerName -eq $capturedComputerName }
        }
        else {
            Mock-NetworkPester -Operation 'Test-Connection' -MockWith $mockWith -Scope $Scope
        }
    }
}

<#
.SYNOPSIS
    Legacy function for backward compatibility.

.DESCRIPTION
    Original Mock-Network function maintained for backward compatibility.
    New code should use Mock-NetworkPester instead.
#>
function Mock-Network {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Invoke-WebRequest', 'Invoke-RestMethod', 'Test-Connection', 'Resolve-DnsName', 'netstat')]
        [string]$Operation,

        [scriptblock]$MockWith,

        [object]$ReturnValue,

        [switch]$UsePesterMock
    )

    # Default to Pester mocking if available
    if (-not $UsePesterMock) {
        $UsePesterMock = (Get-Command Mock -ErrorAction SilentlyContinue) -ne $null
    }

    if ($UsePesterMock) {
        $params = @{
            Operation = $Operation
        }
        if ($MockWith) {
            $params['MockWith'] = $MockWith
        }
        elseif ($null -ne $ReturnValue) {
            $params['ReturnValue'] = $ReturnValue
        }
        Mock-NetworkPester @params
        return
    }

    # Function-based mocking (legacy)
    $original = Get-Command $Operation -ErrorAction SilentlyContinue
    if (-not $original) {
        Write-Warning "Command $Operation not found. Cannot create function-based mock."
        return
    }

    $mockScript = if ($MockWith) {
        $MockWith
    }
    elseif ($null -ne $ReturnValue) {
        { return $ReturnValue }
    }
    else {
        { Write-Verbose "Mock: Would execute $Operation" }
    }

    Set-Item -Path "Function:\$Operation" -Value $mockScript -Force -ErrorAction SilentlyContinue
    Register-Mock -Type 'Function' -Name $Operation -MockValue $mockScript -Original $original
}

# Export functions
Export-ModuleMember -Function @(
    'Mock-Network',
    'Mock-NetworkPester',
    'Mock-WebRequestSuccess',
    'Mock-WebRequestFailure',
    'Mock-RestMethodSuccess',
    'Mock-TestConnection'
)

