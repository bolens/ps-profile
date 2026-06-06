# New-QrCodeUrl

## Synopsis

Generates a URL QR code.

## Description

Creates a QR code for a URL. Automatically adds https:// if no protocol is specified. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCodeUrl
```

## Parameters

### -Url

The URL to encode. This parameter is mandatory.

### -Title

Optional title for the URL (not encoded in QR code, for reference only).

### -OutputPath

The path where the QR code image will be saved. If not specified, defaults to url-{hostname}.png in current directory.

### -Size

The size of the QR code in pixels. Default is 200.

### -ErrorCorrectionLevel

Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.


## Examples

### Example 1

`powershell
New-QrCodeUrl -Url "example.com"
    Generates a QR code for https://example.com.
``

### Example 2

`powershell
New-QrCodeUrl -Url "https://example.com" -Title "My Website"
    Generates a QR code for the URL with a title reference.
``

## Aliases

This function has the following aliases:

- `qrcode-url` - Generates a URL QR code.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-communication.ps1
