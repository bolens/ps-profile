# New-QrCodeEmail

## Synopsis

Generates an email QR code.

## Description

Creates a QR code that can be scanned to compose an email. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCodeEmail
```

## Parameters

### -Email

The email address. This parameter is mandatory.

### -Subject

Optional email subject.

### -Body

Optional email body text.

### -OutputPath

The path where the QR code image will be saved. If not specified, defaults to email-{email}.png in current directory.

### -Size

The size of the QR code in pixels. Default is 200.

### -ErrorCorrectionLevel

Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.


## Examples

### Example 1

`powershell
New-QrCodeEmail -Email "contact@example.com" -Subject "Hello" -Body "Message body"
    Generates an email QR code with subject and body.
``

## Aliases

This function has the following aliases:

- `qrcode-email` - Generates an email QR code.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-communication.ps1
