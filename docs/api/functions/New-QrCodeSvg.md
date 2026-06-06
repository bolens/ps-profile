# New-QrCodeSvg

## Synopsis

Generates a QR code as an SVG image.

## Description

Creates a scalable QR code SVG file from the provided data. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCodeSvg
```

## Parameters

### -Data

The data to encode in the QR code.

### -OutputPath

The path where the QR code SVG will be saved.

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
New-QrCodeSvg -Data "https://example.com" -OutputPath "qrcode.svg"
    Generates a scalable SVG QR code for the URL.
``

## Aliases

This function has the following aliases:

- `qrcode-svg` - Generates a QR code as an SVG image.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-formats.ps1
