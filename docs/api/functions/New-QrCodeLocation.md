# New-QrCodeLocation

## Synopsis

Generates a geolocation QR code.

## Description

Creates a QR code containing GPS coordinates that can be scanned to open in maps. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCodeLocation
```

## Parameters

### -Latitude

The latitude coordinate. This parameter is mandatory.

### -Longitude

The longitude coordinate. This parameter is mandatory.

### -Altitude

Optional altitude in meters.

### -OutputPath

The path where the QR code image will be saved. If not specified, defaults to location-{lat},{lon}.png in current directory.

### -Size

The size of the QR code in pixels. Default is 200.

### -ErrorCorrectionLevel

Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.


## Examples

### Example 1

```powershell
New-QrCodeLocation -Latitude 40.7128 -Longitude -74.0060
```

Generates a geolocation QR code for New York City.

## Aliases

This function has the following aliases:

- `qrcode-location` - Generates a geolocation QR code.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-specialized.ps1
