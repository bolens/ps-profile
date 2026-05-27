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
    if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
        Invoke-WithWideEvent -OperationName 'network.ports.get' -Context @{} -ScriptBlock {
            if (-not (Test-CachedCommand 'netstat')) {
                throw "netstat command not found. This command is typically available on Windows and Unix systems."
            }
            & netstat -an
        }
    }
    else {
        try {
            if (-not (Test-CachedCommand 'netstat')) {
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
}
Set-AgentModeAlias -Name 'ports' -Target 'Get-NetworkPorts'
# ptest equivalent
<#
.SYNOPSIS
    Tests network connectivity.
.DESCRIPTION
    Tests connectivity to specified hosts using ping.
#>
function Test-NetworkConnection { Test-Connection @args }
Set-AgentModeAlias -Name 'ptest' -Target 'Test-NetworkConnection'
# dns equivalent
<#
.SYNOPSIS
    Resolves DNS names.
.DESCRIPTION
    Performs DNS lookups for hostnames or IP addresses.
#>
function Resolve-DnsNameCustom { Resolve-DnsName @args }
Set-AgentModeAlias -Name 'dns' -Target 'Resolve-DnsNameCustom'
# rest equivalent
<#
.SYNOPSIS
    Makes REST API calls.
.DESCRIPTION
    Sends HTTP requests to REST APIs and returns the response.
#>
function Invoke-RestApi { Invoke-RestMethod @args }
Set-AgentModeAlias -Name 'rest' -Target 'Invoke-RestApi'
# web equivalent
<#
.SYNOPSIS
    Makes HTTP web requests.
.DESCRIPTION
    Downloads content from web URLs or sends HTTP requests.
#>
function Invoke-WebRequestCustom { Invoke-WebRequest @args }
Set-AgentModeAlias -Name 'web' -Target 'Invoke-WebRequestCustom'