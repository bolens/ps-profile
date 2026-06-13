# _New-QrCodeUrl

## Synopsis

Initializes communication-specific QR code generation functions.

## Description

Sets up internal functions for generating QR codes for communication (URL, SMS, Email, Phone). This function is called automatically by Initialize-DevTools-QrCode.

## Signature

```powershell
_New-QrCodeUrl [String]$Url, [String]$Title, [String]$OutputPath, [Int32]$Size, [String]$ErrorCorrectionLevel
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires Node.js and qrcode package.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-communication.ps1
