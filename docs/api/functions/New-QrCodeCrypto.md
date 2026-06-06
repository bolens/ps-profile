# New-QrCodeCrypto

## Synopsis

Generates a cryptocurrency payment QR code.

## Description

Creates a QR code for cryptocurrency payments that can be scanned by wallet apps. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCodeCrypto
```

## Parameters

### -Address

The cryptocurrency wallet address. This parameter is mandatory.

### -Currency

The cryptocurrency type: bitcoin, ethereum, litecoin, bitcoincash, monero, or custom. Default is bitcoin.

### -Amount

Optional payment amount.

### -Label

Optional payment label/description.

### -Message

Optional payment message.

### -OutputPath

The path where the QR code image will be saved. If not specified, defaults to crypto-{currency}.png in current directory.

### -Size

The size of the QR code in pixels. Default is 200.

### -ErrorCorrectionLevel

Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.


## Examples

### Example 1

`powershell
New-QrCodeCrypto -Address "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa" -Currency bitcoin -Amount 0.001
    Generates a Bitcoin payment QR code.
``

## Aliases

This function has the following aliases:

- `qrcode-crypto` - Generates a cryptocurrency payment QR code.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-specialized.ps1
