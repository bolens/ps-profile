# New-QrCode

## Synopsis

Generates a QR code image from data.

## Description

Creates a QR code image file from the provided data with customizable options. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCode
```

## Parameters

### -Data

The data to encode in the QR code.

### -OutputPath

The path where the QR code image will be saved.

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

```powershell
New-QrCode -Data "https://example.com" -OutputPath "qrcode.png"
```

Generates a QR code for the URL.

### Example 2

```powershell
New-QrCode -Data "Hello World" -OutputPath "hello.png" -Size 300 -ErrorCorrectionLevel H
```

Generates a larger QR code with high error correction.

### Example 3

```powershell
New-QrCode -Data "Custom Colors" -OutputPath "custom.png" -DarkColor "#FF0000" -LightColor "#FFFF00"
```

Generates a QR code with red foreground and yellow background.

## Aliases

This function has the following aliases:

- `qrcode` - Generates a QR code image from data.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode.ps1
