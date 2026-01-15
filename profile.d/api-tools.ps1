# ===============================================
# api-tools.ps1
# API development and testing tools
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

<#
.SYNOPSIS
    API tools fragment for API development, testing, and debugging.

.DESCRIPTION
    Provides wrapper functions for API development tools:
    - bruno: API client for testing REST APIs
    - postman: API development platform
    - hurl: HTTP testing tool for running HTTP requests
    - httpie: Command-line HTTP client
    - insomnia: API client and testing tool
    - httptoolkit: HTTP debugging proxy

.NOTES
    All functions gracefully degrade when tools are not installed.
    Use Register-ToolWrapper for simple wrappers and custom functions for complex operations.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'api-tools') { return }
    }
    
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
        }
        else {
            Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        
        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # Bruno - API client
    # ===============================================

    <#
    .SYNOPSIS
        Runs Bruno API collections.
    
    .DESCRIPTION
        Executes Bruno API collections for testing REST APIs.
        Bruno is a lightweight, fast, and modern API client.
    
    .PARAMETER CollectionPath
        Path to the Bruno collection file or directory.
        If not specified, uses current directory.
    
    .PARAMETER Environment
        Environment name to use for the collection.
    
    .EXAMPLE
        Invoke-Bruno -CollectionPath "./api-collection"
        Runs the Bruno collection in the specified directory.
    
    .EXAMPLE
        Invoke-Bruno -Environment "production"
        Runs the Bruno collection using the production environment.
    
    .OUTPUTS
        System.String. Output from Bruno execution.
    #>
    function Invoke-Bruno {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
            [string]$CollectionPath,
            
            [Parameter()]
            [string]$Environment
        )

        process {
            if (-not (Test-CachedCommand 'bruno')) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
                $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                    Get-ToolInstallHint -ToolName 'bruno' -RepoRoot $repoRoot
                }
                else {
                    "Install with: scoop install bruno"
                }
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -Tool 'bruno' -InstallHint $installHint
                }
                else {
                    Write-Warning "bruno not found. $installHint"
                }
                return $null
            }

            $collection = if ([string]::IsNullOrWhiteSpace($CollectionPath)) {
                (Get-Location).Path
            }
            else {
                $CollectionPath
            }

            if (-not (Test-Path -LiteralPath $collection)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("Collection path not found: $collection"),
                            'CollectionPathNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $collection
                        )) -OperationName 'api.bruno.run' -Context @{ collection_path = $collection }
                }
                else {
                    Write-Error "Collection path not found: $collection"
                }
                return $null
            }

            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                return Invoke-WithWideEvent -OperationName 'api.bruno.run' -Context @{
                    collection_path = $collection
                    environment     = $Environment
                } -ScriptBlock {
                    $args = @('run', $collection)
                    if (-not [string]::IsNullOrWhiteSpace($Environment)) {
                        $args += @('--env', $Environment)
                    }
                    & bruno $args 2>&1
                }
            }
            else {
                try {
                    $args = @('run', $collection)
                    if (-not [string]::IsNullOrWhiteSpace($Environment)) {
                        $args += @('--env', $Environment)
                    }
                    $result = & bruno $args 2>&1
                    return $result
                }
                catch {
                    Write-Error "Failed to run bruno: $($_.Exception.Message)"
                    return $null
                }
            }
        }
    }

    if (-not (Test-Path Function:\Invoke-Bruno -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-Bruno' -Body ${function:Invoke-Bruno}
        Set-AgentModeAlias -Name 'bruno' -Target 'Invoke-Bruno'
    }

    # ===============================================
    # Hurl - HTTP testing tool
    # ===============================================

    <#
    .SYNOPSIS
        Executes Hurl test files.
    
    .DESCRIPTION
        Runs HTTP requests defined in Hurl test files.
        Hurl is a command-line tool that runs HTTP requests defined in a simple plain text format.
    
    .PARAMETER TestFile
        Path to the Hurl test file (.hurl).
        If not specified, searches for .hurl files in current directory.
    
    .PARAMETER Variable
        Set a variable for the test execution (can be used multiple times).
        Format: "name=value"
    
    .PARAMETER Output
        Output file path for the response.
    
    .EXAMPLE
        Invoke-Hurl -TestFile "./api-tests.hurl"
        Runs the specified Hurl test file.
    
    .EXAMPLE
        Invoke-Hurl -TestFile "./test.hurl" -Variable "base_url=https://api.example.com"
        Runs the test with a variable set.
    
    .OUTPUTS
        System.String. Output from Hurl execution.
    #>
    function Invoke-Hurl {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
            [string]$TestFile,
            
            [Parameter()]
            [string[]]$Variable,
            
            [Parameter()]
            [string]$Output
        )

        process {
            if (-not (Test-CachedCommand 'hurl')) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
                $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                    Get-ToolInstallHint -ToolName 'hurl' -RepoRoot $repoRoot
                }
                else {
                    "Install with: scoop install hurl"
                }
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -Tool 'hurl' -InstallHint $installHint
                }
                else {
                    Write-Warning "hurl not found. $installHint"
                }
                return $null
            }

            if (-not (Test-Path -LiteralPath $TestFile)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("Test file not found: $TestFile"),
                            'TestFileNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $TestFile
                        )) -OperationName 'api.hurl.run' -Context @{ test_file = $TestFile }
                }
                else {
                    Write-Error "Test file not found: $TestFile"
                }
                return $null
            }

            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                return Invoke-WithWideEvent -OperationName 'api.hurl.run' -Context @{
                    test_file     = $TestFile
                    has_variables = ($null -ne $Variable)
                    output_file   = $Output
                } -ScriptBlock {
                    $args = @($TestFile)
                    if ($Variable) {
                        foreach ($var in $Variable) {
                            $args += @('--variable', $var)
                        }
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Output)) {
                        $args += @('--output', $Output)
                    }
                    & hurl $args 2>&1
                }
            }
            else {
                try {
                    $args = @($TestFile)
                    if ($Variable) {
                        foreach ($var in $Variable) {
                            $args += @('--variable', $var)
                        }
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Output)) {
                        $args += @('--output', $Output)
                    }
                    $result = & hurl $args 2>&1
                    return $result
                }
                catch {
                    Write-Error "Failed to run hurl: $($_.Exception.Message)"
                    return $null
                }
            }
        }
    }

    if (-not (Test-Path Function:\Invoke-Hurl -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-Hurl' -Body ${function:Invoke-Hurl}
        Set-AgentModeAlias -Name 'hurl' -Target 'Invoke-Hurl'
    }

    # ===============================================
    # Httpie - Command-line HTTP client
    # ===============================================

    <#
    .SYNOPSIS
        Makes HTTP requests using httpie.
    
    .DESCRIPTION
        Executes HTTP requests using httpie, a user-friendly command-line HTTP client.
        Supports GET, POST, PUT, DELETE, PATCH, and other HTTP methods.
    
    .PARAMETER Method
        HTTP method (GET, POST, PUT, DELETE, PATCH, etc.).
        Defaults to GET if not specified.
    
    .PARAMETER Url
        The URL to request.
    
    .PARAMETER Body
        Request body (for POST, PUT, PATCH requests).
    
    .PARAMETER Header
        Custom headers (can be used multiple times).
        Format: "Header-Name: value"
    
    .PARAMETER Output
        Output file path for the response.
    
    .EXAMPLE
        Invoke-Httpie -Method GET -Url "https://api.example.com/users"
        Makes a GET request to the specified URL.
    
    .EXAMPLE
        Invoke-Httpie -Method POST -Url "https://api.example.com/users" -Body '{"name":"John"}'
        Makes a POST request with a JSON body.
    
    .OUTPUTS
        System.String. HTTP response from httpie.
    #>
    function Invoke-Httpie {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter()]
            [string]$Method = 'GET',
            
            [Parameter(Mandatory, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
            [string]$Url,
            
            [Parameter()]
            [string]$Body,
            
            [Parameter()]
            [string[]]$Header,
            
            [Parameter()]
            [string]$Output
        )

        process {
            if (-not (Test-CachedCommand 'http')) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
                $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                    Get-ToolInstallHint -ToolName 'httpie' -RepoRoot $repoRoot
                }
                else {
                    "Install with: scoop install httpie"
                }
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -Tool 'httpie' -InstallHint $installHint
                }
                else {
                    Write-Warning "httpie not found. $installHint"
                }
                return $null
            }

            if ([string]::IsNullOrWhiteSpace($Url)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.ArgumentException]::new("URL is required"),
                            'UrlRequired',
                            [System.Management.Automation.ErrorCategory]::InvalidArgument,
                            $null
                        )) -OperationName 'api.httpie.request' -Context @{ method = $Method }
                }
                else {
                    Write-Error "URL is required"
                }
                return $null
            }

            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                return Invoke-WithWideEvent -OperationName 'api.httpie.request' -Context @{
                    method      = $Method
                    url         = $Url
                    has_body    = (-not [string]::IsNullOrWhiteSpace($Body))
                    has_headers = ($null -ne $Header)
                    output_file = $Output
                } -ScriptBlock {
                    $args = @()
                    if ($Method -ne 'GET') {
                        $args += $Method
                    }
                    $args += $Url
                    if (-not [string]::IsNullOrWhiteSpace($Body)) {
                        $args += $Body
                    }
                    if ($Header) {
                        foreach ($h in $Header) {
                            $args += $h
                        }
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Output)) {
                        $args += @('--output', $Output)
                    }
                    & http $args 2>&1
                }
            }
            else {
                try {
                    $args = @()
                    if ($Method -ne 'GET') {
                        $args += $Method
                    }
                    $args += $Url
                    if (-not [string]::IsNullOrWhiteSpace($Body)) {
                        $args += $Body
                    }
                    if ($Header) {
                        foreach ($h in $Header) {
                            $args += $h
                        }
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Output)) {
                        $args += @('--output', $Output)
                    }
                    $result = & http $args 2>&1
                    return $result
                }
                catch {
                    Write-Error "Failed to run httpie: $($_.Exception.Message)"
                    return $null
                }
            }
        }
    }

    if (-not (Test-Path Function:\Invoke-Httpie -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-Httpie' -Body ${function:Invoke-Httpie}
        Set-AgentModeAlias -Name 'httpie' -Target 'Invoke-Httpie'
    }

    # ===============================================
    # HTTP Toolkit - HTTP debugging proxy
    # ===============================================

    <#
    .SYNOPSIS
        Starts HTTP Toolkit proxy server.
    
    .DESCRIPTION
        Launches HTTP Toolkit, an HTTP debugging proxy that intercepts and inspects HTTP/HTTPS traffic.
        Useful for debugging API calls, inspecting requests/responses, and testing applications.
    
    .PARAMETER Port
        Port number for the proxy server.
        Defaults to 8000 if not specified.
    
    .PARAMETER Passthrough
        If specified, starts the proxy in passthrough mode (does not intercept traffic).
    
    .EXAMPLE
        Start-HttpToolkit
        Starts HTTP Toolkit on the default port (8000).
    
    .EXAMPLE
        Start-HttpToolkit -Port 9000
        Starts HTTP Toolkit on port 9000.
    
    .OUTPUTS
        System.Diagnostics.Process. Process object for the HTTP Toolkit proxy.
    #>
    function Start-HttpToolkit {
        [CmdletBinding()]
        [OutputType([System.Diagnostics.Process])]
        param(
            [Parameter()]
            [int]$Port = 8000,
            
            [Parameter()]
            [switch]$Passthrough
        )

        if (-not (Test-CachedCommand 'httptoolkit')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'httptoolkit' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install httptoolkit"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'httptoolkit' -InstallHint $installHint
            }
            else {
                Write-Warning "httptoolkit not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'api.httptoolkit.start' -Context @{
                port        = $Port
                passthrough = $Passthrough.IsPresent
            } -ScriptBlock {
                $args = @('--port', $Port.ToString())
                if ($Passthrough) {
                    $args += '--passthrough'
                }
                Start-Process -FilePath 'httptoolkit' -ArgumentList $args -PassThru -NoNewWindow
            }
        }
        else {
            try {
                $args = @('--port', $Port.ToString())
                if ($Passthrough) {
                    $args += '--passthrough'
                }
                $process = Start-Process -FilePath 'httptoolkit' -ArgumentList $args -PassThru -NoNewWindow
                return $process
            }
            catch {
                Write-Error "Failed to start httptoolkit: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Start-HttpToolkit -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Start-HttpToolkit' -Body ${function:Start-HttpToolkit}
        Set-AgentModeAlias -Name 'httptoolkit' -Target 'Start-HttpToolkit'
    }

    # ===============================================
    # Insomnia - API client
    # ===============================================

    <#
    .SYNOPSIS
        Runs Insomnia API requests or collections.
    
    .DESCRIPTION
        Executes Insomnia API requests or collections using the Insomnia CLI.
        Insomnia is a powerful API client with support for REST, GraphQL, gRPC, and more.
    
    .PARAMETER CollectionPath
        Path to the Insomnia collection file or directory.
        If not specified, uses current directory.
    
    .PARAMETER Environment
        Environment name to use for the collection.
    
    .EXAMPLE
        Invoke-Insomnia -CollectionPath "./api-collection"
        Runs the Insomnia collection in the specified directory.
    
    .EXAMPLE
        Invoke-Insomnia -Environment "production"
        Runs the Insomnia collection using the production environment.
    
    .OUTPUTS
        System.String. Output from Insomnia execution.
    #>
    function Invoke-Insomnia {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
            [string]$CollectionPath,
            
            [Parameter()]
            [string]$Environment
        )

        process {
            if (-not (Test-CachedCommand 'insomnia')) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
                $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                    Get-ToolInstallHint -ToolName 'insomnia' -RepoRoot $repoRoot
                }
                else {
                    "Install with: scoop install insomnia"
                }
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -Tool 'insomnia' -InstallHint $installHint
                }
                else {
                    Write-Warning "insomnia not found. $installHint"
                }
                return $null
            }

            $collection = if ([string]::IsNullOrWhiteSpace($CollectionPath)) {
                (Get-Location).Path
            }
            else {
                $CollectionPath
            }

            if (-not (Test-Path -LiteralPath $collection)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("Collection path not found: $collection"),
                            'CollectionPathNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $collection
                        )) -OperationName 'api.insomnia.run' -Context @{ collection_path = $collection }
                }
                else {
                    Write-Error "Collection path not found: $collection"
                }
                return $null
            }

            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                return Invoke-WithWideEvent -OperationName 'api.insomnia.run' -Context @{
                    collection_path = $collection
                    environment     = $Environment
                } -ScriptBlock {
                    $args = @('run', $collection)
                    if (-not [string]::IsNullOrWhiteSpace($Environment)) {
                        $args += @('--env', $Environment)
                    }
                    & insomnia $args 2>&1
                }
            }
            else {
                try {
                    $args = @('run', $collection)
                    if (-not [string]::IsNullOrWhiteSpace($Environment)) {
                        $args += @('--env', $Environment)
                    }
                    $result = & insomnia $args 2>&1
                    return $result
                }
                catch {
                    Write-Error "Failed to run insomnia: $($_.Exception.Message)"
                    return $null
                }
            }
        }
    }

    if (-not (Test-Path Function:\Invoke-Insomnia -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-Insomnia' -Body ${function:Invoke-Insomnia}
        Set-AgentModeAlias -Name 'insomnia' -Target 'Invoke-Insomnia'
    }

    # ===============================================
    # Postman - API development platform (via Newman CLI)
    # ===============================================

    <#
    .SYNOPSIS
        Runs Postman collections using Newman CLI.
    
    .DESCRIPTION
        Executes Postman collections using Newman, the command-line companion for Postman.
        Newman allows you to run and test Postman collections from the command line.
    
    .PARAMETER CollectionPath
        Path to the Postman collection file (JSON).
        Can be a local file path or a Postman collection URL.
    
    .PARAMETER Environment
        Path to Postman environment file (JSON).
    
    .PARAMETER Reporters
        Reporters to use for output (cli, json, html, junit).
        Can be used multiple times.
    
    .PARAMETER OutputFile
        Output file path for reports.
    
    .EXAMPLE
        Invoke-Postman -CollectionPath "./collection.json"
        Runs the Postman collection.
    
    .EXAMPLE
        Invoke-Postman -CollectionPath "./collection.json" -Environment "./env.json" -Reporters "html", "json"
        Runs the collection with environment and generates HTML and JSON reports.
    
    .OUTPUTS
        System.String. Output from Newman execution.
    #>
    function Invoke-Postman {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
            [string]$CollectionPath,
            
            [Parameter()]
            [string]$Environment,
            
            [Parameter()]
            [string[]]$Reporters,
            
            [Parameter()]
            [string]$OutputFile
        )

        process {
            if (-not (Test-CachedCommand 'newman')) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
                $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                    Get-ToolInstallHint -ToolName 'newman' -RepoRoot $repoRoot
                }
                else {
                    "Install with: npm install -g newman"
                }
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -Tool 'newman' -InstallHint $installHint
                }
                else {
                    Write-Warning "newman (Postman CLI) not found. $installHint"
                }
                return $null
            }

            if (-not (Test-Path -LiteralPath $CollectionPath)) {
                # Check if it's a URL (starts with http:// or https://)
                if (-not ($CollectionPath -match '^https?://')) {
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                                [System.IO.FileNotFoundException]::new("Collection path not found: $CollectionPath"),
                                'CollectionPathNotFound',
                                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                                $CollectionPath
                            )) -OperationName 'api.postman.run' -Context @{ collection_path = $CollectionPath }
                    }
                    else {
                        Write-Error "Collection path not found: $CollectionPath"
                    }
                    return $null
                }
            }

            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                return Invoke-WithWideEvent -OperationName 'api.postman.run' -Context @{
                    collection_path = $CollectionPath
                    environment     = $Environment
                    reporters       = $Reporters
                    output_file     = $OutputFile
                } -ScriptBlock {
                    $args = @('run', $CollectionPath)
                    if (-not [string]::IsNullOrWhiteSpace($Environment)) {
                        if (-not (Test-Path -LiteralPath $Environment)) {
                            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                                        [System.IO.FileNotFoundException]::new("Environment file not found: $Environment"),
                                        'EnvironmentFileNotFound',
                                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                                        $Environment
                                    )) -OperationName 'api.postman.run' -Context @{ environment_file = $Environment }
                            }
                            else {
                                Write-Error "Environment file not found: $Environment"
                            }
                            return $null
                        }
                        $args += @('--environment', $Environment)
                    }
                    if ($Reporters) {
                        foreach ($reporter in $Reporters) {
                            $args += @('--reporter', $reporter)
                            if (-not [string]::IsNullOrWhiteSpace($OutputFile)) {
                                $reporterOutput = if ($Reporters.Count -eq 1) {
                                    $OutputFile
                                }
                                else {
                                    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($OutputFile)
                                    $extension = [System.IO.Path]::GetExtension($OutputFile)
                                    $dir = Split-Path -Parent $OutputFile
                                    Join-Path $dir "$baseName-$reporter$extension"
                                }
                                $args += $reporterOutput
                            }
                        }
                    }
                    & newman $args 2>&1
                }
            }
            else {
                try {
                    $args = @('run', $CollectionPath)
                    if (-not [string]::IsNullOrWhiteSpace($Environment)) {
                        if (-not (Test-Path -LiteralPath $Environment)) {
                            Write-Error "Environment file not found: $Environment"
                            return $null
                        }
                        $args += @('--environment', $Environment)
                    }
                    if ($Reporters) {
                        foreach ($reporter in $Reporters) {
                            $args += @('--reporter', $reporter)
                            if (-not [string]::IsNullOrWhiteSpace($OutputFile)) {
                                $reporterOutput = if ($Reporters.Count -eq 1) {
                                    $OutputFile
                                }
                                else {
                                    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($OutputFile)
                                    $extension = [System.IO.Path]::GetExtension($OutputFile)
                                    $dir = Split-Path -Parent $OutputFile
                                    Join-Path $dir "$baseName-$reporter$extension"
                                }
                                $args += $reporterOutput
                            }
                        }
                    }
                    $result = & newman $args 2>&1
                    return $result
                }
                catch {
                    Write-Error "Failed to run newman: $($_.Exception.Message)"
                    return $null
                }
            }
        }
    }

    if (-not (Test-Path Function:\Invoke-Postman -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-Postman' -Body ${function:Invoke-Postman}
        Set-AgentModeAlias -Name 'postman' -Target 'Invoke-Postman'
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'api-tools'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'api-tools' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load api-tools fragment: $($_.Exception.Message)"
    }
}
