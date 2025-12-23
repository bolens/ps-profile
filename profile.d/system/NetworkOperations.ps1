# ===============================================
# NetworkOperations.ps1
# Network operation utilities
# ===============================================

# Network ports and connections (Unix 'netstat' equivalent)
<#
.SYNOPSIS
    Shows network port information.
.DESCRIPTION
    Displays active network connections and listening ports using netstat.
#>
function Get-NetworkPorts {
    try {
        if (-not (Get-Command netstat -ErrorAction SilentlyContinue)) {
            Write-Error "netstat command not found. This command is typically available on Windows and Unix systems."
            return
        }
        & netstat -an
    }
    catch {
        Write-Error "Failed to get network ports: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name ports -Value Get-NetworkPorts -ErrorAction SilentlyContinue

# ptest equivalent
<#
.SYNOPSIS
    Tests network connectivity.
.DESCRIPTION
    Tests connectivity to specified hosts using ping.
#>
function Test-NetworkConnection { Test-Connection @args }
Set-Alias -Name ptest -Value Test-NetworkConnection -ErrorAction SilentlyContinue

# dns equivalent
<#
.SYNOPSIS
    Resolves DNS names.
.DESCRIPTION
    Performs DNS lookups for hostnames or IP addresses.
#>
function Resolve-DnsNameCustom { Resolve-DnsName @args }
Set-Alias -Name dns -Value Resolve-DnsNameCustom -ErrorAction SilentlyContinue

# rest equivalent
<#
.SYNOPSIS
    Makes REST API calls.
.DESCRIPTION
    Sends HTTP requests to REST APIs and returns the response.
#>
function Invoke-RestApi { Invoke-RestMethod @args }
Set-Alias -Name rest -Value Invoke-RestApi -ErrorAction SilentlyContinue

# web equivalent
<#
.SYNOPSIS
    Makes HTTP web requests.
.DESCRIPTION
    Downloads content from web URLs or sends HTTP requests.
#>
function Invoke-WebRequestCustom { Invoke-WebRequest @args }
Set-Alias -Name web -Value Invoke-WebRequestCustom -ErrorAction SilentlyContinue

