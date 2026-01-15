# ===============================================
# network-analysis.ps1
# Network analysis and monitoring tools
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: server, development

<#
.SYNOPSIS
    Network analysis and monitoring tools fragment.

.DESCRIPTION
    Provides wrapper functions for network analysis and monitoring tools:
    - wireshark: Network protocol analyzer
    - sniffnet: Network monitoring
    - trippy: Network diagnostic tool
    - nali: IP geolocation
    - ipinfo-cli: IP information tool
    - cloudflared: Cloudflare tunnel
    - ntfy: Push notifications

.NOTES
    All functions gracefully degrade when tools are not installed.
    Use Register-ToolWrapper for simple wrappers and custom functions for complex operations.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'network-analysis') { return }
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
    # Start-Wireshark - Launch Wireshark capture
    # ===============================================

    <#
    .SYNOPSIS
        Launches Wireshark network protocol analyzer.
    
    .DESCRIPTION
        Starts Wireshark with optional capture file or interface selection.
        Wireshark is a network protocol analyzer for capturing and analyzing
        network traffic.
    
    .PARAMETER CaptureFile
        Optional path to a capture file to open in Wireshark.
    
    .PARAMETER Interface
        Optional network interface name to start capturing on.
    
    .EXAMPLE
        Start-Wireshark
        
        Launches Wireshark with default settings.
    
    .EXAMPLE
        Start-Wireshark -CaptureFile "capture.pcap"
        
        Opens the specified capture file in Wireshark.
    
    .EXAMPLE
        Start-Wireshark -Interface "Ethernet"
        
        Starts Wireshark capturing on the specified interface.
    #>
    function Start-Wireshark {
        [CmdletBinding()]
        param(
            [string]$CaptureFile,
            
            [string]$Interface
        )

        if (-not (Test-CachedCommand 'wireshark')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'wireshark' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -ToolName 'wireshark' -InstallHint $installHint
            }
            else {
                Write-Warning "wireshark is not installed. Install it with: scoop install wireshark"
            }
            return
        }

        $arguments = @()
        
        if ($CaptureFile) {
            if (-not (Test-Path -LiteralPath $CaptureFile)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("Capture file not found: $CaptureFile"),
                            'CaptureFileNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $CaptureFile
                        )) -OperationName 'network.wireshark.start' -Context @{ capture_file = $CaptureFile }
                }
                else {
                    Write-Error "Capture file not found: $CaptureFile"
                }
                return
            }
            $arguments += $CaptureFile
        }
        
        if ($Interface) {
            $arguments += '-i', $Interface
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'network.wireshark.start' -Context @{
                capture_file = $CaptureFile
                interface    = $Interface
            } -ScriptBlock {
                Start-Process -FilePath 'wireshark' -ArgumentList $arguments -ErrorAction Stop
            } | Out-Null
        }
        else {
            try {
                Start-Process -FilePath 'wireshark' -ArgumentList $arguments -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch wireshark: $_"
            }
        }
    }

    # ===============================================
    # Invoke-NetworkScan - Network scanning utilities
    # ===============================================

    <#
    .SYNOPSIS
        Performs network scanning using available tools.
    
    .DESCRIPTION
        Uses sniffnet or trippy for network scanning and diagnostics.
        Supports different scan types and output formats.
    
    .PARAMETER Target
        Target host or network to scan (IP address or CIDR).
    
    .PARAMETER Tool
        Tool to use: sniffnet or trippy. Defaults to sniffnet.
    
    .PARAMETER OutputFormat
        Output format: text, json. Defaults to text.
    
    .EXAMPLE
        Invoke-NetworkScan -Target "192.168.1.0/24"
        
        Scans the specified network using sniffnet.
    
    .EXAMPLE
        Invoke-NetworkScan -Target "192.168.1.1" -Tool "trippy"
        
        Performs network diagnostics on the target using trippy.
    #>
    function Invoke-NetworkScan {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Target,
            
            [ValidateSet('sniffnet', 'trippy')]
            [string]$Tool = 'sniffnet',
            
            [ValidateSet('text', 'json')]
            [string]$OutputFormat = 'text'
        )

        if ($Tool -eq 'sniffnet') {
            if (-not (Test-CachedCommand 'sniffnet')) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
                $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                    Get-ToolInstallHint -ToolName 'sniffnet' -RepoRoot $repoRoot
                }
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -ToolName 'sniffnet' -InstallHint $installHint
                }
                else {
                    Write-Warning "sniffnet is not installed. Install it with: scoop install sniffnet"
                }
                return
            }

            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                Invoke-WithWideEvent -OperationName 'network.scan.sniffnet' -Context @{
                    target        = $Target
                    output_format = $OutputFormat
                } -ScriptBlock {
                    # Sniffnet is primarily a GUI tool, but can be launched
                    Start-Process -FilePath 'sniffnet' -ErrorAction Stop
                } | Out-Null
            }
            else {
                try {
                    # Sniffnet is primarily a GUI tool, but can be launched
                    Start-Process -FilePath 'sniffnet' -ErrorAction Stop
                }
                catch {
                    Write-Error "Failed to launch sniffnet: $_"
                }
            }
        }
        elseif ($Tool -eq 'trippy') {
            if (-not (Test-CachedCommand 'trippy')) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
                $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                    Get-ToolInstallHint -ToolName 'trippy' -RepoRoot $repoRoot
                }
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -ToolName 'trippy' -InstallHint $installHint
                }
                else {
                    Write-Warning "trippy is not installed. Install it with: scoop install trippy"
                }
                return
            }

            $arguments = @($Target)
            
            if ($OutputFormat -eq 'json') {
                $arguments += '--json'
            }

            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                return Invoke-WithWideEvent -OperationName 'network.scan.trippy' -Context @{
                    target        = $Target
                    output_format = $OutputFormat
                } -ScriptBlock {
                    $output = & trippy $arguments 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Trippy scan failed. Exit code: $LASTEXITCODE"
                    }
                    return $output
                }
            }
            else {
                try {
                    $output = & trippy $arguments 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Trippy scan failed. Exit code: $LASTEXITCODE"
                    }
                }
                catch {
                    Write-Error "Failed to run trippy: $_"
                }
            }
        }
    }

    # ===============================================
    # Get-IpInfo - Get IP geolocation info
    # ===============================================

    <#
    .SYNOPSIS
        Gets IP address geolocation and information.
    
    .DESCRIPTION
        Uses nali or ipinfo-cli to get geolocation and other information
        about an IP address.
    
    .PARAMETER IpAddress
        IP address to query. If not specified, queries the public IP.
    
    .PARAMETER Tool
        Tool to use: nali or ipinfo. Defaults to nali.
    
    .PARAMETER OutputFormat
        Output format: text, json. Defaults to text.
    
    .EXAMPLE
        Get-IpInfo
        
        Gets information about the current public IP address.
    
    .EXAMPLE
        Get-IpInfo -IpAddress "8.8.8.8"
        
        Gets information about the specified IP address.
    
    .EXAMPLE
        Get-IpInfo -IpAddress "8.8.8.8" -Tool "ipinfo" -OutputFormat "json"
        
        Gets IP information using ipinfo-cli in JSON format.
    
    .OUTPUTS
        System.String. IP information in the specified format.
    #>
    function Get-IpInfo {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$IpAddress,
            
            [ValidateSet('nali', 'ipinfo')]
            [string]$Tool = 'nali',
            
            [ValidateSet('text', 'json')]
            [string]$OutputFormat = 'text'
        )

        if ($Tool -eq 'nali') {
            if (-not (Test-CachedCommand 'nali')) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
                $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                    Get-ToolInstallHint -ToolName 'nali' -RepoRoot $repoRoot
                }
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -ToolName 'nali' -InstallHint $installHint
                }
                else {
                    Write-Warning "nali is not installed. Install it with: scoop install nali"
                }
                return
            }

            try {
                if ($IpAddress) {
                    $output = & nali $IpAddress 2>&1
                }
                else {
                    # For public IP, use dig first, then nali
                    $publicIp = & dig +short myip.opendns.com '@resolver1.opendns.com' 2>&1
                    if ($LASTEXITCODE -eq 0 -and $publicIp) {
                        $output = & nali $publicIp.Trim() 2>&1
                    }
                    else {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                                    [System.Exception]::new("Failed to get public IP address"),
                                    'PublicIpLookupFailed',
                                    [System.Management.Automation.ErrorCategory]::OperationStopped,
                                    $null
                                )) -OperationName 'network.ipinfo.nali' -Context @{ tool = 'nali' }
                        }
                        else {
                            Write-Error "Failed to get public IP address"
                        }
                        return
                    }
                }
                
                if ($LASTEXITCODE -ne 0) {
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                                [System.Exception]::new("Nali query failed. Exit code: $LASTEXITCODE"),
                                'NaliQueryFailed',
                                [System.Management.Automation.ErrorCategory]::OperationStopped,
                                $LASTEXITCODE
                            )) -OperationName 'network.ipinfo.nali' -Context @{ tool = 'nali'; exit_code = $LASTEXITCODE }
                    }
                    else {
                        Write-Error "Nali query failed. Exit code: $LASTEXITCODE"
                    }
                    return
                }
                return $output
            }
            catch {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'network.ipinfo.nali' -Context @{ tool = 'nali' }
                }
                else {
                    Write-Error "Failed to run nali: $_"
                }
            }
        }
        elseif ($Tool -eq 'ipinfo') {
            if (-not (Test-CachedCommand 'ipinfo')) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
                $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                    Get-ToolInstallHint -ToolName 'ipinfo-cli' -RepoRoot $repoRoot
                }
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -ToolName 'ipinfo' -InstallHint $installHint
                }
                else {
                    Write-Warning "ipinfo is not installed. Install it with: scoop install ipinfo-cli"
                }
                return
            }

            $arguments = @()
            
            if ($OutputFormat -eq 'json') {
                $arguments += '--json'
            }
            
            if ($IpAddress) {
                $arguments += $IpAddress
            }

            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                return Invoke-WithWideEvent -OperationName 'network.ipinfo.query' -Context @{
                    tool          = 'ipinfo'
                    ip_address    = $IpAddress
                    output_format = $OutputFormat
                } -ScriptBlock {
                    $output = & ipinfo $arguments 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Ipinfo query failed. Exit code: $LASTEXITCODE"
                    }
                    return $output
                }
            }
            else {
                try {
                    $output = & ipinfo $arguments 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Ipinfo query failed. Exit code: $LASTEXITCODE"
                    }
                }
                catch {
                    Write-Error "Failed to run ipinfo: $_"
                }
            }
        }
    }

    # ===============================================
    # Start-CloudflareTunnel - Start Cloudflare tunnel
    # ===============================================

    <#
    .SYNOPSIS
        Starts a Cloudflare tunnel using cloudflared.
    
    .DESCRIPTION
        Creates a secure tunnel to expose local services through Cloudflare.
        Supports HTTP, TCP, and other tunnel types.
    
    .PARAMETER Url
        Local URL or service to tunnel (e.g., http://localhost:8080).
    
    .PARAMETER Hostname
        Optional Cloudflare hostname for the tunnel.
    
    .PARAMETER Protocol
        Tunnel protocol: http, tcp, ssh, rdp. Defaults to http.
    
    .EXAMPLE
        Start-CloudflareTunnel -Url "http://localhost:8080"
        
        Creates an HTTP tunnel to the local service.
    
    .EXAMPLE
        Start-CloudflareTunnel -Url "tcp://localhost:22" -Protocol "ssh"
        
        Creates an SSH tunnel.
    #>
    function Start-CloudflareTunnel {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Url,
            
            [string]$Hostname,
            
            [ValidateSet('http', 'tcp', 'ssh', 'rdp')]
            [string]$Protocol = 'http'
        )

        if (-not (Test-CachedCommand 'cloudflared')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'cloudflared' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -ToolName 'cloudflared' -InstallHint $installHint
            }
            else {
                Write-Warning "cloudflared is not installed. Install it with: scoop install cloudflared"
            }
            return
        }

        if (-not $PSCmdlet.ShouldProcess($Url, "Start Cloudflare tunnel")) {
            return
        }

        $arguments = @('tunnel', '--url', $Url)
        
        if ($Hostname) {
            $arguments += '--hostname', $Hostname
        }
        
        if ($Protocol -ne 'http') {
            $arguments += '--protocol', $Protocol
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'network.cloudflare.tunnel.start' -Context @{
                url      = $Url
                hostname = $Hostname
                protocol = $Protocol
            } -ScriptBlock {
                & cloudflared $arguments
            } | Out-Null
        }
        else {
            try {
                & cloudflared $arguments
            }
            catch {
                Write-Error "Failed to start Cloudflare tunnel: $_"
            }
        }
    }

    # ===============================================
    # Send-NtfyNotification - Send push notification
    # ===============================================

    <#
    .SYNOPSIS
        Sends a push notification using ntfy.
    
    .DESCRIPTION
        Sends push notifications to devices using the ntfy service.
        Supports custom topics, priorities, and message formatting.
    
    .PARAMETER Message
        Notification message text.
    
    .PARAMETER Topic
        Ntfy topic name. Defaults to a random topic if not specified.
    
    .PARAMETER Title
        Optional notification title.
    
    .PARAMETER Priority
        Notification priority: low, default, high, urgent. Defaults to default.
    
    .PARAMETER Server
        Optional ntfy server URL. Defaults to ntfy.sh.
    
    .EXAMPLE
        Send-NtfyNotification -Message "Task completed successfully"
        
        Sends a notification with the specified message.
    
    .EXAMPLE
        Send-NtfyNotification -Message "Alert!" -Title "System Alert" -Priority "urgent" -Topic "alerts"
        
        Sends an urgent notification to the alerts topic.
    
    .OUTPUTS
        System.String. Notification delivery status.
    #>
    function Send-NtfyNotification {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message,
            
            [string]$Topic,
            
            [string]$Title,
            
            [ValidateSet('low', 'default', 'high', 'urgent')]
            [string]$Priority = 'default',
            
            [string]$Server
        )

        if (-not (Test-CachedCommand 'ntfy')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'ntfy' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -ToolName 'ntfy' -InstallHint $installHint
            }
            else {
                Write-Warning "ntfy is not installed. Install it with: scoop install ntfy"
            }
            return
        }

        $arguments = @('publish')
        
        if ($Topic) {
            $arguments += $Topic
        }
        else {
            # Generate a random topic if not specified
            $randomTopic = -join ((48..57) + (97..122) | Get-Random -Count 8 | ForEach-Object { [char]$_ })
            $arguments += $randomTopic
        }
        
        if ($Title) {
            $arguments += '--title', $Title
        }
        
        if ($Priority -ne 'default') {
            $arguments += '--priority', $Priority
        }
        
        if ($Server) {
            $arguments += '--server', $Server
        }
        
        $arguments += $Message

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'network.ntfy.send' -Context @{
                topic    = $Topic
                priority = $Priority
                server   = $Server
            } -ScriptBlock {
                $output = & ntfy $arguments 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Ntfy notification failed. Exit code: $LASTEXITCODE"
                }
                return $output
            }
        }
        else {
            try {
                $output = & ntfy $arguments 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $output
                }
                else {
                    Write-Error "Ntfy notification failed. Exit code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Error "Failed to send ntfy notification: $_"
            }
        }
    }

    # Register functions and aliases
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Start-Wireshark' -Body ${function:Start-Wireshark}
        Set-AgentModeFunction -Name 'Invoke-NetworkScan' -Body ${function:Invoke-NetworkScan}
        Set-AgentModeFunction -Name 'Get-IpInfo' -Body ${function:Get-IpInfo}
        Set-AgentModeFunction -Name 'Start-CloudflareTunnel' -Body ${function:Start-CloudflareTunnel}
        Set-AgentModeFunction -Name 'Send-NtfyNotification' -Body ${function:Send-NtfyNotification}
    }
    else {
        # Fallback: direct function registration
        Set-Item -Path Function:Start-Wireshark -Value ${function:Start-Wireshark} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Invoke-NetworkScan -Value ${function:Invoke-NetworkScan} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-IpInfo -Value ${function:Get-IpInfo} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Start-CloudflareTunnel -Value ${function:Start-CloudflareTunnel} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Send-NtfyNotification -Value ${function:Send-NtfyNotification} -Force -ErrorAction SilentlyContinue
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'network-analysis'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: network-analysis" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load network-analysis fragment: $($_.Exception.Message)"
    }
}
