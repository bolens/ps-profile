# New-QrCodeContact

## Synopsis

Generates a contact card (vCard) QR code.

## Description

Creates a QR code containing contact information in vCard format that can be scanned to add to contacts. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCodeContact
```

## Parameters

### -Name

The contact's full name. This parameter is mandatory.

### -Phone

The contact's phone number.

### -Email

The contact's email address.

### -Organization

The contact's organization or company.

### -Url

The contact's website URL.

### -Address

The contact's address.

### -OutputPath

The path where the QR code image will be saved. If not specified, defaults to contact-{Name}.png in current directory.

### -Size

The size of the QR code in pixels. Default is 200.

### -ErrorCorrectionLevel

Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.


## Examples

### Example 1

`powershell
New-QrCodeContact -Name "John Doe" -Phone "+1234567890" -Email "john@example.com"
    Generates a contact QR code with name, phone, and email.
``

## Aliases

This function has the following aliases:

- `qrcode-contact` - Generates a contact card (vCard) QR code.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-specialized.ps1
