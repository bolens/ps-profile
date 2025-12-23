# network-analysis.ps1

Network analysis and monitoring tools fragment.

## Overview

The `network-analysis.ps1` fragment provides wrapper functions for network analysis, monitoring, and diagnostic tools, including:

- **Network protocol analysis** with Wireshark
- **Network monitoring** with Sniffnet
- **Network diagnostics** with Trippy
- **IP geolocation** with Nali and ipinfo-cli
- **Cloudflare tunnels** with cloudflared
- **Push notifications** with ntfy

## Dependencies

- `bootstrap.ps1` - Core bootstrap functions
- `env.ps1` - Environment configuration

## Functions

### Start-Wireshark

Launches Wireshark network protocol analyzer.

**Syntax:**

```powershell
Start-Wireshark [-CaptureFile <string>] [-Interface <string>] [<CommonParameters>]
```

**Parameters:**

- `CaptureFile` - Optional path to a capture file to open in Wireshark.
- `Interface` - Optional network interface name to start capturing on.

**Examples:**

```powershell
# Launch Wireshark with default settings
Start-Wireshark

# Open a capture file in Wireshark
Start-Wireshark -CaptureFile "capture.pcap"

# Start capturing on a specific interface
Start-Wireshark -Interface "Ethernet"
```

**Installation:**

```powershell
scoop install wireshark
```

---

### Invoke-NetworkScan

Performs network scanning using available tools.

**Syntax:**

```powershell
Invoke-NetworkScan -Target <string> [-Tool <string>] [-OutputFormat <string>] [<CommonParameters>]
```

**Parameters:**

- `Target` (Required) - Target host or network to scan (IP address or CIDR).
- `Tool` - Tool to use: sniffnet or trippy. Defaults to sniffnet.
- `OutputFormat` - Output format: text, json. Defaults to text.

**Examples:**

```powershell
# Scan a network using sniffnet
Invoke-NetworkScan -Target "192.168.1.0/24"

# Perform network diagnostics using trippy
Invoke-NetworkScan -Target "192.168.1.1" -Tool "trippy"

# Get JSON output from trippy
Invoke-NetworkScan -Target "192.168.1.1" -Tool "trippy" -OutputFormat "json"
```

**Installation:**

```powershell
scoop install sniffnet  # Network monitoring GUI
scoop install trippy     # Network diagnostic tool
```

---

### Get-IpInfo

Gets IP address geolocation and information.

**Syntax:**

```powershell
Get-IpInfo [-IpAddress <string>] [-Tool <string>] [-OutputFormat <string>] [<CommonParameters>]
```

**Parameters:**

- `IpAddress` - IP address to query. If not specified, queries the public IP.
- `Tool` - Tool to use: nali or ipinfo. Defaults to nali.
- `OutputFormat` - Output format: text, json. Defaults to text.

**Examples:**

```powershell
# Get information about current public IP
Get-IpInfo

# Get information about a specific IP address
Get-IpInfo -IpAddress "8.8.8.8"

# Get IP information using ipinfo-cli in JSON format
Get-IpInfo -IpAddress "8.8.8.8" -Tool "ipinfo" -OutputFormat "json"
```

**Installation:**

```powershell
scoop install nali        # IP geolocation tool
scoop install ipinfo-cli  # IP information tool
```

---

### Start-CloudflareTunnel

Starts a Cloudflare tunnel using cloudflared.

**Syntax:**

```powershell
Start-CloudflareTunnel -Url <string> [-Hostname <string>] [-Protocol <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

**Parameters:**

- `Url` (Required) - Local URL or service to tunnel (e.g., http://localhost:8080).
- `Hostname` - Optional Cloudflare hostname for the tunnel.
- `Protocol` - Tunnel protocol: http, tcp, ssh, rdp. Defaults to http.

**Examples:**

```powershell
# Create an HTTP tunnel to a local service
Start-CloudflareTunnel -Url "http://localhost:8080"

# Create a tunnel with a custom hostname
Start-CloudflareTunnel -Url "http://localhost:8080" -Hostname "example.com"

# Create an SSH tunnel
Start-CloudflareTunnel -Url "tcp://localhost:22" -Protocol "ssh"
```

**Installation:**

```powershell
scoop install cloudflared
```

---

### Send-NtfyNotification

Sends a push notification using ntfy.

**Syntax:**

```powershell
Send-NtfyNotification -Message <string> [-Topic <string>] [-Title <string>] [-Priority <string>] [-Server <string>] [<CommonParameters>]
```

**Parameters:**

- `Message` (Required) - Notification message text.
- `Topic` - Ntfy topic name. Defaults to a random topic if not specified.
- `Title` - Optional notification title.
- `Priority` - Notification priority: low, default, high, urgent. Defaults to default.
- `Server` - Optional ntfy server URL. Defaults to ntfy.sh.

**Examples:**

```powershell
# Send a simple notification
Send-NtfyNotification -Message "Task completed successfully"

# Send an urgent notification with title and topic
Send-NtfyNotification -Message "Alert!" -Title "System Alert" -Priority "urgent" -Topic "alerts"

# Send notification to a custom server
Send-NtfyNotification -Message "Test" -Server "https://ntfy.example.com"
```

**Installation:**

```powershell
scoop install ntfy
```

---

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions check for tool availability using `Test-CachedCommand`
- Missing tools display installation hints using `Write-MissingToolWarning`
- Functions return `$null` when tools are unavailable
- No errors are thrown for missing tools (graceful degradation)

## Installation

Install required tools using Scoop:

```powershell
# Install all network analysis tools
scoop install wireshark sniffnet trippy nali ipinfo-cli cloudflared ntfy

# Or install individually
scoop install wireshark    # Network protocol analyzer
scoop install sniffnet     # Network monitoring
scoop install trippy       # Network diagnostic tool
scoop install nali         # IP geolocation
scoop install ipinfo-cli   # IP information tool
scoop install cloudflared  # Cloudflare tunnel
scoop install ntfy         # Push notifications
```

## Testing

The fragment includes comprehensive test coverage:

- **Unit tests**: Individual function tests with mocking
- **Integration tests**: Fragment loading and function registration
- **Performance tests**: Load time and function execution performance

Run tests:

```powershell
# Run unit tests
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/network-analysis.ps1

# Run integration tests
Invoke-Pester tests/integration/tools/network-analysis.tests.ps1

# Run performance tests
Invoke-Pester tests/performance/network-analysis-performance.tests.ps1
```

## Notes

- All functions are idempotent and can be safely called multiple times
- Functions use `Set-AgentModeFunction` for registration
- Wireshark and Sniffnet are primarily GUI tools
- Trippy provides command-line network diagnostics
- Nali and ipinfo-cli provide IP geolocation and information
- Cloudflared creates secure tunnels through Cloudflare
- Ntfy sends push notifications to devices
