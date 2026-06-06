# New-QrCodeWiFi

## Synopsis

Generates a WiFi network QR code.

## Description

Creates a QR code that can be scanned to automatically connect to a WiFi network. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCodeWiFi
```

## Parameters

### -Ssid

The WiFi network name (SSID). This parameter is mandatory.

### -Password

The WiFi network password. This parameter is mandatory.

### -Security

The security type: WPA, WEP, or nopass. Default is WPA.

### -Hidden

Whether the network is hidden. Default is false.

### -OutputPath

The path where the QR code image will be saved. If not specified, defaults to wifi-{SSID}.png in current directory.

### -Size

The size of the QR code in pixels. Default is 200.

### -ErrorCorrectionLevel

Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.


## Examples

### Example 1

`powershell
New-QrCodeWiFi -Ssid "MyNetwork" -Password "MyPassword123"
    Generates a WiFi QR code that can be scanned to connect to the network.
``

## Aliases

This function has the following aliases:

- `qrcode-wifi` - Generates a WiFi network QR code.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-specialized.ps1
