# New-QrCodePhone

## Synopsis

Generates a phone call QR code.

## Description

Creates a QR code that can be scanned to make a phone call. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCodePhone
```

## Parameters

### -PhoneNumber

The phone number to call. This parameter is mandatory.

### -OutputPath

The path where the QR code image will be saved. If not specified, defaults to phone-{number}.png in current directory.

### -Size

The size of the QR code in pixels. Default is 200.

### -ErrorCorrectionLevel

Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.


## Examples

### Example 1

```powershell
New-QrCodePhone -PhoneNumber "+1234567890"
```

Generates a phone call QR code.

## Aliases

This function has the following aliases:

- `qrcode-phone` - Generates a phone call QR code.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-communication.ps1
