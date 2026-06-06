# ConvertFrom-QrCodeToText

## Synopsis

Converts QR Code image to text.

## Description

Decodes a QR code image and extracts the text data. Note: Full decoding requires additional image processing libraries (qrcode-reader, zbar, etc.).

## Signature

```powershell
ConvertFrom-QrCodeToText
```

## Parameters

### -InputPath

The path to the QR code image file (.png, .jpg, .jpeg, .gif, .bmp).

### -OutputPath

The path for the output text file. If not specified, uses input path with .txt extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertFrom-QrCodeToText -InputPath "qrcode.png"
    
    Decodes qrcode.png to qrcode.txt.
``

## Notes

Full QR code decoding requires additional libraries. This function currently indicates the requirement.


## Aliases

This function has the following aliases:

- `qrcode-to-text` - Converts QR Code image to text.


## Source

Defined in: ../profile.d/conversion-modules/specialized/specialized-qrcode.ps1
