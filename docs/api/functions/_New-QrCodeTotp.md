# _New-QrCodeTotp

## Synopsis

Format: otpauth://totp/Issuer:AccountName?secret=Secret&issuer=Issuer&algorithm=Algorithm&digits=Digits&period=Period

## Description

Format: otpauth://totp/Issuer:AccountName?secret=Secret&issuer=Issuer&algorithm=Algorithm&digits=Digits&period=Period

## Signature

```powershell
_New-QrCodeTotp [String]$Secret, [String]$Issuer, [String]$AccountName, [String]$Algorithm, [Int32]$Digits, [Int32]$Period, [String]$OutputPath, [Int32]$Size, [String]$ErrorCorrectionLevel
```

## Parameters

No parameters.

## Examples

No examples provided.

## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-specialized.ps1
