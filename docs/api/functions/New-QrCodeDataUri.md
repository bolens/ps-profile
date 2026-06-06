# New-QrCodeDataUri

## Synopsis

Generates a QR code as a data URI.

## Description

Creates a QR code and returns it as a data URI string that can be embedded in HTML or used directly. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCodeDataUri
```

## Parameters

### -Data

The data to encode in the QR code.

### -Size

The size of the QR code in pixels. Default is 200.

### -ErrorCorrectionLevel

Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.

### -DarkColor

Color of the dark modules (foreground). Default is #000000 (black).

### -LightColor

Color of the light modules (background). Default is #FFFFFF (white).

### -Margin

Margin size in modules. Default is 4.


## Examples

### Example 1

`powershell
$dataUri = New-QrCodeDataUri -Data "https://example.com"
    Returns a data URI that can be used in HTML img tags.
``

## Aliases

This function has the following aliases:

- `qrcode-uri` - Generates a QR code as a data URI.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-formats.ps1
