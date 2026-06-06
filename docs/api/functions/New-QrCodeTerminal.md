# New-QrCodeTerminal

## Synopsis

Displays a QR code in the terminal.

## Description

Generates and displays a QR code directly in the terminal using ASCII characters. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCodeTerminal
```

## Parameters

### -Data

The data to encode in the QR code.

### -Small

Use a smaller version of the terminal QR code.


## Examples

### Example 1

`powershell
New-QrCodeTerminal -Data "https://example.com"
    Displays a QR code in the terminal that can be scanned.
``

## Aliases

This function has the following aliases:

- `qrcode-term` - Displays a QR code in the terminal.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-formats.ps1
