# Get-IpInfo

## Synopsis

Gets IP address geolocation and information.

## Description

Uses nali or ipinfo-cli to get geolocation and other information about an IP address.

## Signature

```powershell
Get-IpInfo
```

## Parameters

### -IpAddress

IP address to query. If not specified, queries the public IP.

### -Tool

Tool to use: nali or ipinfo. Defaults to nali.

### -OutputFormat

Output format: text, json. Defaults to text.


## Outputs

System.String. IP information in the specified format.


## Examples

### Example 1

`powershell
Get-IpInfo
        
        Gets information about the current public IP address.
``

### Example 2

`powershell
Get-IpInfo -IpAddress "8.8.8.8"
        
        Gets information about the specified IP address.
``

### Example 3

`powershell
Get-IpInfo -IpAddress "8.8.8.8" -Tool "ipinfo" -OutputFormat "json"
        
        Gets IP information using ipinfo-cli in JSON format.
``

## Source

Defined in: ..\profile.d\network-analysis.ps1
