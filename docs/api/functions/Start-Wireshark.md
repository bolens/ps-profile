# Start-Wireshark

## Synopsis

Launches Wireshark network protocol analyzer.

## Description

Starts Wireshark with optional capture file or interface selection. Wireshark is a network protocol analyzer for capturing and analyzing network traffic.

## Signature

```powershell
Start-Wireshark
```

## Parameters

### -CaptureFile

Optional path to a capture file to open in Wireshark.

### -Interface

Optional network interface name to start capturing on.


## Examples

### Example 1

`powershell
Start-Wireshark
        
        Launches Wireshark with default settings.
``

### Example 2

`powershell
Start-Wireshark -CaptureFile "capture.pcap"
        
        Opens the specified capture file in Wireshark.
``

### Example 3

`powershell
Start-Wireshark -Interface "Ethernet"
        
        Starts Wireshark capturing on the specified interface.
``

## Source

Defined in: ..\profile.d\network-analysis.ps1
