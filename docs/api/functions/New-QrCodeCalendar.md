# New-QrCodeCalendar

## Synopsis

Generates a calendar event QR code.

## Description

Creates a QR code containing a calendar event in iCal format that can be scanned to add to calendar. Requires Node.js and qrcode package.

## Signature

```powershell
New-QrCodeCalendar
```

## Parameters

### -Title

The event title. This parameter is mandatory.

### -StartTime

The event start time. This parameter is mandatory.

### -EndTime

The event end time. This parameter is mandatory.

### -Location

Optional event location.

### -Description

Optional event description.

### -OutputPath

The path where the QR code image will be saved. If not specified, defaults to calendar-{title}.png in current directory.

### -Size

The size of the QR code in pixels. Default is 200.

### -ErrorCorrectionLevel

Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.


## Examples

### Example 1

`powershell
$start = Get-Date "2024-12-25 10:00"
    $end = Get-Date "2024-12-25 12:00"
    New-QrCodeCalendar -Title "Meeting" -StartTime $start -EndTime $end -Location "Conference Room"
    Generates a calendar event QR code.
``

## Aliases

This function has the following aliases:

- `qrcode-calendar` - Generates a calendar event QR code.


## Source

Defined in: ../profile.d/dev-tools-modules/format/qrcode/qrcode-specialized.ps1
