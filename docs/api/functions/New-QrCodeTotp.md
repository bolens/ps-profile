# New-QrCodeTotp

## Synopsis

Generates a TOTP/2FA QR code.

## Description

Creates a QR code for Time-based One-Time Password (TOTP) authentication that can be scanned by authenticator apps. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCodeTotp
```

## Parameters

### -Secret

The TOTP secret key (base32 encoded). This parameter is mandatory.

### -Issuer

The service/issuer name (e.g., "GitHub", "Google"). This parameter is mandatory.

### -AccountName

The account name or username. This parameter is mandatory.

### -Algorithm

The hash algorithm: SHA1, SHA256, or SHA512. Default is SHA1.

### -Digits

The number of digits in the TOTP code. Default is 6.

### -Period

The time period in seconds. Default is 30.

### -OutputPath

The path where the QR code image will be saved. If not specified, defaults to totp-{account}.png in current directory.

### -Size

The size of the QR code in pixels. Default is 200.

### -ErrorCorrectionLevel

Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.


## Examples

### Example 1

```powershell
New-QrCodeTotp -Secret "JBSWY3DPEHPK3PXP" -Issuer "GitHub" -AccountName "user@example.com"
```

Generates a TOTP QR code for GitHub authentication.

## Aliases

This function has the following aliases:

- `qrcode-totp` - Generates a TOTP/2FA QR code.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-specialized.ps1
