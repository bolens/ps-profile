# New-QrCodeSms

## Synopsis

Generates an SMS/text message QR code.

## Description

Creates a QR code that can be scanned to send an SMS message. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCodeSms
```

## Parameters

### -PhoneNumber

The phone number to send the SMS to. This parameter is mandatory.

### -Message

Optional pre-filled message text.

### -OutputPath

The path where the QR code image will be saved. If not specified, defaults to sms-{phone}.png in current directory.

### -Size

The size of the QR code in pixels. Default is 200.

### -ErrorCorrectionLevel

Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.


## Examples

### Example 1

`powershell
New-QrCodeSms -PhoneNumber "+1234567890" -Message "Hello!"
    Generates an SMS QR code with a pre-filled message.
``

## Aliases

This function has the following aliases:

- `qrcode-sms` - Generates an SMS/text message QR code.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-communication.ps1
