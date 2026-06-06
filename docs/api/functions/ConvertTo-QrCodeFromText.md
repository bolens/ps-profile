# ConvertTo-QrCodeFromText

## Synopsis

Converts text file to QR Code image.

## Description

Reads text from a file and generates a QR code image containing that text. Requires Node.js and qrcode package.

## Signature

```powershell
ConvertTo-QrCodeFromText
```

## Parameters

### -InputPath

The path to the text file (.txt or .text extension).

### -OutputPath

The path for the output QR code image file. If not specified, uses input path with .png extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertTo-QrCodeFromText -InputPath "data.txt"
    
    Converts data.txt to data.png QR code.
``

## Aliases

This function has the following aliases:

- `text-to-qrcode` - Converts text file to QR Code image.


## Source

Defined in: ../profile.d/conversion-modules/specialized/specialized-qrcode.ps1
